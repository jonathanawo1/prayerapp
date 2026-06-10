import logging, json
from bs4 import BeautifulSoup
from monitors.base import BaseMonitor
logger = logging.getLogger(__name__)

IN_STOCK = ["add to basket", "add to cart", "add to bag", "add to trolley", "buy now", "in stock"]
OUT_STOCK = ["out of stock", "sold out", "unavailable", "currently unavailable", "not available", "no longer available"]

class GenericMonitor(BaseMonitor):
    SITE_NAME = "generic"
    async def check(self, url):
        r = {"title": None, "image_url": None, "price": None, "in_stock": False, "queue_detected": False}
        if not await self._respect_robots(url): return r
        html = await self._fetch(url)
        if not html: return r
        if self._check_queueit(html): r["queue_detected"] = True; return r
        soup = BeautifulSoup(html, "html.parser")
        og = soup.find("meta", {"property": "og:title"})
        r["title"] = og.get("content", "").strip() if og else None
        if not r["title"]:
            h1 = soup.find("h1")
            if h1: r["title"] = h1.get_text(strip=True)
        ogi = soup.find("meta", {"property": "og:image"})
        if ogi: r["image_url"] = ogi.get("content", "").strip()
        for script in soup.find_all("script", {"type": "application/ld+json"}):
            try:
                d = json.loads(script.string or "")
                if isinstance(d, list): d = d[0]
                if d.get("@type") in ("Product", "Offer"):
                    o = d.get("offers", d)
                    if isinstance(o, list): o = o[0]
                    p2 = o.get("price") or o.get("lowPrice")
                    cur = o.get("priceCurrency", "")
                    if p2: r["price"] = f"{{'GBP':'£','USD':'$','EUR':'€'}.get(cur,'')}{p2}"
                    av = o.get("availability", "")
                    if "InStock" in av: r["in_stock"] = True
                    elif "OutOfStock" in av: r["in_stock"] = False
                    break
            except: continue
        p = html.lower()
        if any(k in p for k in OUT_STOCK): r["in_stock"] = False
        elif any(k in p for k in IN_STOCK): r["in_stock"] = True
        return r
