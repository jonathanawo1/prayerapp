from monitors.very import VeryMonitor
from monitors.asda import AsdaMonitor
from monitors.pokemon_centre import PokemonCentreMonitor
from monitors.topps import ToppsMonitor
from monitors.currys import CurrysMonitor
from monitors.argos import ArgosMonitor
from monitors.amazon import AmazonMonitor
from monitors.smyths import SmythsMonitor
from monitors.game import GameMonitor
from monitors.zavvi import ZavviMonitor
from monitors.hmv import HmvMonitor
from monitors.cex import CexMonitor
from monitors.john_lewis import JohnLewisMonitor
from monitors.generic import GenericMonitor

SITE_MAP = {
    "very.co.uk": ("very", VeryMonitor),
    "asda.com": ("asda", AsdaMonitor),
    "george.com": ("george", AsdaMonitor),
    "pokemoncenter.com": ("pokemon_centre", PokemonCentreMonitor),
    "pokemoncentre.com": ("pokemon_centre", PokemonCentreMonitor),
    "topps.com": ("topps", ToppsMonitor),
    "currys.co.uk": ("currys", CurrysMonitor),
    "argos.co.uk": ("argos", ArgosMonitor),
    "amazon.co.uk": ("amazon", AmazonMonitor),
    "amazon.com": ("amazon", AmazonMonitor),
    "smythstoys.com": ("smyths", SmythsMonitor),
    "game.co.uk": ("game", GameMonitor),
    "zavvi.com": ("zavvi", ZavviMonitor),
    "hmv.com": ("hmv", HmvMonitor),
    "uk.webuy.com": ("cex", CexMonitor),
    "johnlewis.com": ("john_lewis", JohnLewisMonitor),
}

def get_monitor_for_url(url: str):
    url_lower = url.lower()
    for domain, (_, cls) in SITE_MAP.items():
        if domain in url_lower:
            return cls()
    return GenericMonitor()

def detect_site(url: str) -> str:
    url_lower = url.lower()
    for domain, (site, _) in SITE_MAP.items():
        if domain in url_lower:
            return site
    return "generic"
