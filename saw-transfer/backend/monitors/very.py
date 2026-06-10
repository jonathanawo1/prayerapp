import logging, re, json
from bs4 import BeautifulSoup
from monitors.base import BaseMonitor
logger = logging.getLogger(__name__)

class VeryMonitor(BaseMonitor):
    SITE_NAME = "very"
    async def check(self, url):
        r = {"title": None, "image_url": None, "price": None, "in_stock": False, "queue_detected": False}
        if not await self._respect_robots(url): return r
        html = await self._fetch(url)
        if not html: return r
        if self._check_queueit(html): r["queue_detected"] = True; return r
        soup = BeautifulSoup(html, "html.parser")
        h1 = soup.find("h1"); r["title"] = h1.get_text(strip=True) if h1 else None
        pt = soup.find(class_=re.compile(r"price", re.I))
        if pt: t = pt.get_text(strip=True); r["price"] = t[:50] if "£" in t else None
        p = html.lower()
        r["in_stock"] = "add to basket" in p and not any(x in p for x in ["out of stock", "sold out", "currently unavailable"])
        return r
