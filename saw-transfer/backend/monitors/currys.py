import logging, json
from bs4 import BeautifulSoup
from monitors.base import BaseMonitor
logger = logging.getLogger(__name__)

class CurrysMonitor(BaseMonitor):
    SITE_NAME = "currys"
    async def check(self, url):
        r = {"title": None, "image_url": None, "price": None, "in_stock": False, "queue_detected": False}
        if not await self._respect_robots(url): return r
        html = await self._fetch(url)
        if not html: return r
        if self._check_queueit(html): r["queue_detected"] = True; return r
        soup = BeautifulSoup(html, "html.parser")
        h1 = soup.find("h1"); r["title"] = h1.get_text(strip=True) if h1 else None
        jld = soup.find("script", {"type": "application/ld+json"})
        if jld:
            try:
                d = json.loads(jld.string)
                if isinstance(d, list): d = d[0]
                o = d.get("offers", {})
                if isinstance(o, list): o = o[0]
                if o.get("price"): r["price"] = f"£{o['price']}"
                av = o.get("availability", "")
                if "InStock" in av: r["in_stock"] = True
                elif "OutOfStock" in av: r["in_stock"] = False
            except: pass
        p = html.lower()
        if ("add to trolley" in p or "add to basket" in p) and "out of stock" not in p: r["in_stock"] = True
        if "out of stock" in p or "sold out" in p: r["in_stock"] = False
        return r
