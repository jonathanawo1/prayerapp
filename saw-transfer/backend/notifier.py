import logging
import time
from datetime import datetime
from typing import Optional
import httpx

logger = logging.getLogger(__name__)
_last_notified: dict[int, float] = {}
DEBOUNCE_SECONDS = 300

class DiscordNotifier:
    def __init__(self, webhook_url: str):
        self.webhook_url = webhook_url

    async def send(self, product_id: int, title: str, price: Optional[str], status: str, url: str, image_url: Optional[str] = None, event_type: str = "in_stock", extra_fields: Optional[list] = None) -> bool:
        now = time.time()
        if now - _last_notified.get(product_id, 0) < DEBOUNCE_SECONDS:
            return False
        if not self.webhook_url:
            return False
        color_map = {"in_stock": 0x22C55E, "out_of_stock": 0xEF4444, "price_change": 0xEAB308, "deal": 0xF97316, "queue": 0xA855F7}
        color = color_map.get(event_type, 0x6366F1)
        labels = {"in_stock": "IN STOCK", "out_of_stock": "OUT OF STOCK", "price_change": "PRICE CHANGE", "deal": "DEAL ALERT", "queue": "QUEUE LIVE"}
        label = labels.get(event_type, event_type.upper())
        fields = [
            {"name": "Status", "value": label, "inline": True},
            {"name": "Price", "value": price or "Unknown", "inline": True},
            {"name": "Link", "value": f"[View Product]({url})", "inline": False},
        ]
        if extra_fields:
            fields.extend(extra_fields)
        embed = {"title": f"{label}: {title or 'Product Update'}", "url": url, "color": color, "timestamp": datetime.utcnow().isoformat() + "Z", "fields": fields, "footer": {"text": "SAW Stock Alert Watcher"}}
        if image_url:
            embed["thumbnail"] = {"url": image_url}
        try:
            async with httpx.AsyncClient(timeout=15) as client:
                resp = await client.post(self.webhook_url, json={"username": "SAW Stock Watcher", "embeds": [embed]})
                if resp.status_code in (200, 204):
                    _last_notified[product_id] = time.time()
                    return True
                return False
        except Exception as e:
            logger.error(f"Discord error: {e}")
            return False

async def send_telegram(bot_token: str, chat_id: str, text: str) -> bool:
    if not bot_token or not chat_id:
        return False
    try:
        async with httpx.AsyncClient(timeout=15) as client:
            resp = await client.post(f"https://api.telegram.org/bot{bot_token}/sendMessage", json={"chat_id": chat_id, "text": text, "parse_mode": "HTML"})
            return resp.status_code == 200
    except Exception:
        return False

async def test_webhook(webhook_url: str) -> bool:
    try:
        async with httpx.AsyncClient(timeout=15) as client:
            resp = await client.post(webhook_url, json={"username": "SAW", "embeds": [{"title": "Test", "description": "SAW webhook working!", "color": 0x6366F1}]})
            return resp.status_code in (200, 204)
    except Exception:
        return False
