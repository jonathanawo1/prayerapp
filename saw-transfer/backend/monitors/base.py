import asyncio, random, time, logging
from abc import ABC, abstractmethod
from typing import Optional
from urllib.parse import urlparse
from urllib.robotparser import RobotFileParser
from io import StringIO
import httpx

logger = logging.getLogger(__name__)

USER_AGENTS = [
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:121.0) Gecko/20100101 Firefox/121.0",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_2_1) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.2 Safari/605.1.15",
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36 Edg/120.0.0.0",
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
]

_domain_last_fetch: dict[str, float] = {}
_domain_lock: dict[str, asyncio.Lock] = {}
MIN_INTERVAL_PER_DOMAIN = 30
QUEUEIT_INDICATORS = ["queue-it", "queueit", "queue.it", "waiting room", "you are in the queue", "virtual waiting room"]

class BaseMonitor(ABC):
    SITE_NAME: str = "base"
    ROBOTS_CACHE: dict = {}

    def _get_domain(self, url): return urlparse(url).netloc

    def _get_domain_lock(self, domain):
        if domain not in _domain_lock: _domain_lock[domain] = asyncio.Lock()
        return _domain_lock[domain]

    async def _respect_robots(self, url):
        parsed = urlparse(url)
        base = f"{parsed.scheme}://{parsed.netloc}"
        if base not in self.ROBOTS_CACHE:
            try:
                async with httpx.AsyncClient(timeout=10) as c:
                    resp = await c.get(f"{base}/robots.txt")
                    if resp.status_code == 200:
                        rp = RobotFileParser(); rp.parse(StringIO(resp.text).readlines()); self.ROBOTS_CACHE[base] = rp
                    else: self.ROBOTS_CACHE[base] = None
            except: self.ROBOTS_CACHE[base] = None
        rp = self.ROBOTS_CACHE.get(base)
        return True if rp is None else rp.can_fetch("*", url)

    def _check_queueit(self, html): return any(i in html.lower() for i in QUEUEIT_INDICATORS)

    async def _fetch(self, url, max_retries=3):
        domain = self._get_domain(url)
        lock = self._get_domain_lock(domain)
        async with lock:
            now = time.time(); last = _domain_last_fetch.get(domain, 0)
            wait = MIN_INTERVAL_PER_DOMAIN - (now - last)
            if wait > 0 and last != 0: await asyncio.sleep(wait)
            headers = {"User-Agent": random.choice(USER_AGENTS), "Accept": "text/html,*/*;q=0.8", "Accept-Language": "en-GB,en;q=0.9"}
            for attempt in range(max_retries):
                try:
                    async with httpx.AsyncClient(timeout=30, follow_redirects=True, headers=headers) as c:
                        resp = await c.get(url); _domain_last_fetch[domain] = time.time()
                        if resp.status_code == 200: return resp.text
                        elif resp.status_code == 429: await asyncio.sleep((2**attempt)*30)
                        else: return None
                except httpx.TimeoutException: await asyncio.sleep((2**attempt)*5)
                except Exception as e: logger.error(f"Fetch error: {e}"); await asyncio.sleep((2**attempt)*5)
            _domain_last_fetch[domain] = time.time(); return None

    @abstractmethod
    async def check(self, url): pass
