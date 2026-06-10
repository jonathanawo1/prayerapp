import asyncio
import csv
import io
import json
import logging
from datetime import datetime
from typing import Optional

from fastapi import FastAPI, Depends, HTTPException, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
from pydantic import BaseModel, validator
from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from database import get_db, init_db, AsyncSessionLocal
from models import MonitoredProduct, AlertEvent, AppSettings, PriceHistory, SaleLedger
from monitors import get_monitor_for_url, detect_site
from notifier import DiscordNotifier, send_telegram, test_webhook
from ebay import search_ebay_sold, calculate_profit

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(name)s: %(message)s")
logger = logging.getLogger(__name__)

app = FastAPI(title="SAW — Stock Alert Watcher", version="2.0.0")
app.add_middleware(CORSMiddleware, allow_origins=["http://localhost:5173", "http://127.0.0.1:5173"], allow_credentials=True, allow_methods=["*"], allow_headers=["*"])


class ConnectionManager:
    def __init__(self): self.active: list[WebSocket] = []
    async def connect(self, ws): await ws.accept(); self.active.append(ws)
    def disconnect(self, ws):
        if ws in self.active: self.active.remove(ws)
    async def broadcast(self, msg):
        dead = []
        for ws in self.active:
            try: await ws.send_json(msg)
            except: dead.append(ws)
        for ws in dead: self.disconnect(ws)


manager = ConnectionManager()
_monitor_tasks: dict[int, asyncio.Task] = {}


async def get_setting(db, key):
    r = await db.execute(select(AppSettings).where(AppSettings.key == key))
    s = r.scalar_one_or_none()
    return s.value if s else None

async def set_setting(db, key, value):
    r = await db.execute(select(AppSettings).where(AppSettings.key == key))
    s = r.scalar_one_or_none()
    if s: s.value = value
    else: db.add(AppSettings(key=key, value=value))
    await db.commit()


async def monitor_product(product_id: int):
    logger.info(f"Starting monitor for product {product_id}")
    while True:
        try:
            async with AsyncSessionLocal() as db:
                r = await db.execute(select(MonitoredProduct).where(MonitoredProduct.id == product_id))
                product = r.scalar_one_or_none()
                if not product or not product.is_active: break

                monitor = get_monitor_for_url(product.url)
                result = await monitor.check(product.url)

                # Queue-it detection
                if result.get("queue_detected"):
                    discord_url = await get_setting(db, "discord_webhook")
                    notifier = DiscordNotifier(discord_url or "")
                    await notifier.send(product_id=product_id, title=product.title or product.url, price=product.price, status="in_stock", url=product.url, event_type="queue")
                    tg_token = await get_setting(db, "telegram_bot_token")
                    tg_chat = await get_setting(db, "telegram_chat_id")
                    await send_telegram(tg_token or "", tg_chat or "", f"\U0001f7e3 QUEUE LIVE: {product.title or product.url}\n{product.url}")
                    await manager.broadcast({"type": "queue_detected", "product_id": product_id, "url": product.url})

                old_status = product.status
                old_price = product.price
                new_status = "in_stock" if result["in_stock"] else "out_of_stock"

                # Track ever_in_stock
                if result["in_stock"] and not product.ever_in_stock:
                    product.ever_in_stock = True

                events = []
                if old_status != new_status:
                    db.add(AlertEvent(product_id=product_id, event_type=new_status, old_value=old_status, new_value=new_status))
                    events.append({"type": new_status})

                if result.get("price") and old_price and result["price"] != old_price:
                    db.add(AlertEvent(product_id=product_id, event_type="price_change", old_value=old_price, new_value=result["price"]))
                    events.append({"type": "price_change", "old": old_price, "new": result["price"]})

                # Price history snapshot
                if result.get("price"):
                    db.add(PriceHistory(product_id=product_id, price=result["price"]))

                product.status = new_status
                product.last_checked = datetime.utcnow()
                if result.get("title"): product.title = result["title"]
                if result.get("image_url"): product.image_url = result["image_url"]
                if result.get("price"): product.price = result["price"]
                await db.commit()
                await db.refresh(product)

                if events:
                    discord_url = await get_setting(db, "discord_webhook")
                    tg_token = await get_setting(db, "telegram_bot_token")
                    tg_chat = await get_setting(db, "telegram_chat_id")
                    notifier = DiscordNotifier(discord_url or "")
                    for ev in events:
                        if ev["type"] in ("in_stock", "price_change"):
                            label = "NEW DROP" if ev["type"] == "in_stock" and not product.ever_in_stock else ev["type"]
                            extra = []
                            if ev["type"] == "in_stock" and not product.ever_in_stock:
                                extra.append({"name": "Tag", "value": "✨ First time in stock!", "inline": True})
                            await notifier.send(product_id=product_id, title=product.title or product.url, price=product.price, status=product.status, url=product.url, image_url=product.image_url, event_type=ev["type"], extra_fields=extra)
                            tg_msg = f"{'✅ IN STOCK' if ev['type']=='in_stock' else '\U0001f4b0 PRICE CHANGE'}: {product.title or product.url}\n{product.url}"
                            await send_telegram(tg_token or "", tg_chat or "", tg_msg)
                    await manager.broadcast({"type": "product_update", "product": _product_dict(product), "events": events})

        except asyncio.CancelledError: break
        except Exception as e: logger.error(f"Monitor error product {product_id}: {e}", exc_info=True)

        try:
            async with AsyncSessionLocal() as db:
                r = await db.execute(select(MonitoredProduct).where(MonitoredProduct.id == product_id))
                p = r.scalar_one_or_none()
                if not p or not p.is_active: break
                interval = max(p.check_interval_seconds, 30)
        except: interval = 60
        await asyncio.sleep(interval)


def start_monitor(pid):
    if pid not in _monitor_tasks or _monitor_tasks[pid].done():
        _monitor_tasks[pid] = asyncio.create_task(monitor_product(pid))

def stop_monitor(pid):
    t = _monitor_tasks.get(pid)
    if t and not t.done(): t.cancel(); del _monitor_tasks[pid]


@app.on_event("startup")
async def startup():
    await init_db()
    async with AsyncSessionLocal() as db:
        r = await db.execute(select(MonitoredProduct).where(MonitoredProduct.is_active == True))
        products = r.scalars().all()
        for p in products: start_monitor(p.id)
    logger.info(f"Resumed {len(products)} monitors")


def _product_dict(p):
    return {"id": p.id, "url": p.url, "site": p.site, "title": p.title, "image_url": p.image_url, "price": p.price, "status": p.status, "is_active": p.is_active, "ever_in_stock": p.ever_in_stock, "check_interval_seconds": p.check_interval_seconds, "last_checked": p.last_checked.isoformat() if p.last_checked else None, "created_at": p.created_at.isoformat()}

def _alert_dict(a, include_product=False):
    d = {"id": a.id, "product_id": a.product_id, "event_type": a.event_type, "old_value": a.old_value, "new_value": a.new_value, "notified": a.notified, "created_at": a.created_at.isoformat()}
    if include_product and a.product: d["product"] = _product_dict(a.product)
    return d


class AddProductRequest(BaseModel):
    url: str
    check_interval_seconds: int = 60
    @validator("check_interval_seconds")
    def validate_interval(cls, v):
        if v < 30: raise ValueError("minimum 30 seconds")
        return v

class UpdateProductRequest(BaseModel):
    is_active: Optional[bool] = None
    check_interval_seconds: Optional[int] = None

class SettingsRequest(BaseModel):
    discord_webhook: Optional[str] = None
    telegram_bot_token: Optional[str] = None
    telegram_chat_id: Optional[str] = None
    deal_threshold_pct: Optional[int] = None

class ProfitCalcRequest(BaseModel):
    buy_price: float
    sell_price: float
    weight_grams: int = 500

class SaleRequest(BaseModel):
    product_title: str
    buy_price: str
    sell_price: str
    fees: str
    postage: str
    net_profit: str


@app.get("/products")
async def list_products(db: AsyncSession = Depends(get_db)):
    r = await db.execute(select(MonitoredProduct).order_by(MonitoredProduct.created_at.desc()))
    return [_product_dict(p) for p in r.scalars().all()]

@app.post("/products", status_code=201)
async def add_product(req: AddProductRequest, db: AsyncSession = Depends(get_db)):
    p = MonitoredProduct(url=req.url, site=detect_site(req.url), check_interval_seconds=req.check_interval_seconds)
    db.add(p); await db.commit(); await db.refresh(p)
    start_monitor(p.id)
    return _product_dict(p)

@app.delete("/products/{pid}", status_code=204)
async def delete_product(pid: int, db: AsyncSession = Depends(get_db)):
    r = await db.execute(select(MonitoredProduct).where(MonitoredProduct.id == pid))
    p = r.scalar_one_or_none()
    if not p: raise HTTPException(404, "Not found")
    stop_monitor(pid); await db.delete(p); await db.commit()

@app.patch("/products/{pid}")
async def update_product(pid: int, req: UpdateProductRequest, db: AsyncSession = Depends(get_db)):
    r = await db.execute(select(MonitoredProduct).where(MonitoredProduct.id == pid))
    p = r.scalar_one_or_none()
    if not p: raise HTTPException(404, "Not found")
    if req.is_active is not None:
        p.is_active = req.is_active
        start_monitor(pid) if req.is_active else stop_monitor(pid)
    if req.check_interval_seconds is not None:
        p.check_interval_seconds = req.check_interval_seconds
    await db.commit(); await db.refresh(p)
    return _product_dict(p)

@app.get("/products/{pid}/price-history")
async def price_history(pid: int, db: AsyncSession = Depends(get_db)):
    r = await db.execute(select(PriceHistory).where(PriceHistory.product_id == pid).order_by(PriceHistory.recorded_at.asc()).limit(200))
    return [{"price": h.price, "recorded_at": h.recorded_at.isoformat()} for h in r.scalars().all()]

@app.get("/alerts")
async def list_alerts(product_id: Optional[int] = None, db: AsyncSession = Depends(get_db)):
    q = select(AlertEvent).options(selectinload(AlertEvent.product)).order_by(AlertEvent.created_at.desc()).limit(500)
    if product_id: q = q.where(AlertEvent.product_id == product_id)
    r = await db.execute(q)
    return [_alert_dict(a, include_product=True) for a in r.scalars().all()]

@app.get("/settings")
async def get_settings(db: AsyncSession = Depends(get_db)):
    keys = ["discord_webhook", "telegram_bot_token", "telegram_chat_id", "deal_threshold_pct"]
    return {k: (await get_setting(db, k) or "") for k in keys}

@app.post("/settings")
async def save_settings(req: SettingsRequest, db: AsyncSession = Depends(get_db)):
    for k, v in req.dict(exclude_none=True).items():
        await set_setting(db, k, str(v))
    return {"ok": True}

@app.post("/settings/test-webhook")
async def test_discord(db: AsyncSession = Depends(get_db)):
    url = await get_setting(db, "discord_webhook")
    if not url: raise HTTPException(400, "No webhook configured")
    ok = await test_webhook(url)
    if not ok: raise HTTPException(502, "Webhook test failed")
    return {"ok": True}

@app.post("/profit/calculate")
async def profit_calc(req: ProfitCalcRequest):
    return calculate_profit(req.buy_price, req.sell_price, req.weight_grams)

@app.get("/profit/ebay-lookup")
async def ebay_lookup(title: str):
    return await search_ebay_sold(title)

@app.get("/sales")
async def list_sales(db: AsyncSession = Depends(get_db)):
    r = await db.execute(select(SaleLedger).order_by(SaleLedger.sold_at.desc()))
    return [{"id": s.id, "product_title": s.product_title, "buy_price": s.buy_price, "sell_price": s.sell_price, "fees": s.fees, "postage": s.postage, "net_profit": s.net_profit, "sold_at": s.sold_at.isoformat()} for s in r.scalars().all()]

@app.post("/sales", status_code=201)
async def add_sale(req: SaleRequest, db: AsyncSession = Depends(get_db)):
    s = SaleLedger(**req.dict())
    db.add(s); await db.commit(); await db.refresh(s)
    return {"id": s.id, "ok": True}

@app.get("/export/csv")
async def export_csv(db: AsyncSession = Depends(get_db)):
    r = await db.execute(select(AlertEvent).options(selectinload(AlertEvent.product)).order_by(AlertEvent.created_at.desc()).limit(10000))
    alerts = r.scalars().all()
    out = io.StringIO()
    w = csv.writer(out)
    w.writerow(["timestamp", "product_title", "product_url", "event_type", "old_value", "new_value"])
    for a in alerts:
        w.writerow([a.created_at.isoformat(), a.product.title if a.product else "", a.product.url if a.product else "", a.event_type, a.old_value or "", a.new_value or ""])
    out.seek(0)
    return StreamingResponse(io.BytesIO(out.getvalue().encode()), media_type="text/csv", headers={"Content-Disposition": "attachment; filename=saw_alerts.csv"})

@app.websocket("/ws")
async def websocket_endpoint(ws: WebSocket):
    await manager.connect(ws)
    try:
        while True:
            data = await ws.receive_text()
            if data == "ping": await ws.send_text("pong")
    except WebSocketDisconnect: manager.disconnect(ws)
    except: manager.disconnect(ws)
