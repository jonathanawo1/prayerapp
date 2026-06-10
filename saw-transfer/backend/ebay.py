import logging
import re
from typing import Optional
import httpx
from bs4 import BeautifulSoup

logger = logging.getLogger(__name__)

ROYAL_MAIL_TIERS = [(100, 1.55), (250, 2.00), (750, 3.35), (2000, 4.49), (20000, 8.50)]
EBAY_FEE_RATE = 0.128

def estimate_postage(weight_grams: int = 500) -> float:
    for max_g, cost in ROYAL_MAIL_TIERS:
        if weight_grams <= max_g:
            return cost
    return 8.50

def calculate_profit(buy_price: float, sell_price: float, weight_grams: int = 500) -> dict:
    postage = estimate_postage(weight_grams)
    ebay_fees = round(sell_price * EBAY_FEE_RATE, 2)
    net = round(sell_price - buy_price - ebay_fees - postage, 2)
    return {"buy_price": buy_price, "sell_price": sell_price, "ebay_fees": ebay_fees, "postage": postage, "net_profit": net, "profitable": net > 0}

async def search_ebay_sold(title: str, max_results: int = 10) -> dict:
    headers = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36", "Accept-Language": "en-GB,en;q=0.9"}
    query = title[:80].replace(" ", "+")
    url = f"https://www.ebay.co.uk/sch/i.html?_nkw={query}&LH_Complete=1&LH_Sold=1&_sop=13"
    try:
        async with httpx.AsyncClient(timeout=20, headers=headers, follow_redirects=True) as client:
            resp = await client.get(url)
            if resp.status_code != 200:
                return {"avg_sold_price": None, "sold_count": 0, "prices": []}
            soup = BeautifulSoup(resp.text, "html.parser")
            prices = []
            for tag in soup.select(".s-item__price")[:max_results]:
                text = tag.get_text(strip=True).replace(",", "")
                m = re.search(r"[\d]+\.?[\d]*", text)
                if m:
                    try: prices.append(float(m.group()))
                    except ValueError: pass
            if not prices:
                return {"avg_sold_price": None, "sold_count": 0, "prices": []}
            return {"avg_sold_price": round(sum(prices)/len(prices), 2), "sold_count": len(prices), "prices": prices}
    except Exception as e:
        logger.error(f"eBay search error: {e}")
        return {"avg_sold_price": None, "sold_count": 0, "prices": []}
