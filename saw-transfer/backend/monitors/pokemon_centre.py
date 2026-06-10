import logging, json, re
from bs4 import BeautifulSoup
from monitors.base import BaseMonitor
logger = logging.getLogger(__name__)

class PokemonCentreMonitor(BaseMonitor):
    SITE_NAME = "pokemon_centre"
    async def check(self, url):
        r = {"title": None, "image_url": None, "price": None, "in_stock": False, "queue_detected": False}
        if not await self._respect_robots(url): return r
        html = await self._fetch(url)
        if not html: return r
        if self._check_queueit(html): r["queue_detected"] = True; r["title"] = "Queue live — join now!"; return r
        soup = BeautifulSoup(html, "html.parser")
        h1 = soup.find("h1"); r["title"] = h1.get_text(strip=True) if h1 else None
        img = soup.find("img", {"class": re.compile(r"product.*image", re.I)})
        if img: r["image_url"] = img.get("src") or img.get("data-src")
        jld = soup.find("script", {"type": "application/ld+json"})
        if jld:
            try:
                d = json.loads(jld.string)
                if isinstance(d, list): d = d[0]
                o = d.get("offers", {})
                if isinstance(o, list): o = o[0]
                if o.get("price"): r["price"] = f"${o['price']}"
                av = o.get("availability", "")
                if "InStock" in av: r["in_stock"] = True
                elif "OutOfStock" in av: r["in_stock"] = False
            except: pass
        p = html.lower()
        if ("add to cart" in p or "pre-order" in p) and "out of stock" not in p and "sold out" not in p: r["in_stock"] = True
        if "out of stock" in p or "sold out" in p: r["in_stock"] = False
        return r
