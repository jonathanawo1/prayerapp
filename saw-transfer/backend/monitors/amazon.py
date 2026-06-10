import logging
from bs4 import BeautifulSoup
from monitors.base import BaseMonitor
logger = logging.getLogger(__name__)

class AmazonMonitor(BaseMonitor):
    SITE_NAME = "amazon"
    async def check(self, url):
        r = {"title": None, "image_url": None, "price": None, "in_stock": False, "queue_detected": False}
        if not await self._respect_robots(url): return r
        html = await self._fetch(url)
        if not html: return r
        soup = BeautifulSoup(html, "html.parser")
        t = soup.find(id="productTitle")
        if t: r["title"] = t.get_text(strip=True)
        pw = soup.find(class_="a-price-whole"); pf = soup.find(class_="a-price-fraction")
        if pw: r["price"] = f"£{pw.get_text(strip=True).replace(',','').rstrip('.')}.{pf.get_text(strip=True) if pf else '00'}"
        img = soup.find(id="landingImage")
        if img: r["image_url"] = img.get("src")
        p = html.lower()
        r["in_stock"] = ("add to basket" in p or "add to cart" in p) and "currently unavailable" not in p and "out of stock" not in p
        return r
