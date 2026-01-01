"""
Link Fetcher - Fetches links from Stanford Encyclopedia of Philosophy, Wikipedia, etc.
Follows the hierarchy: SEP > PhilPapers > Scholarpedia > arXiv > IEP > Wikipedia
"""

import requests
import json
import re
import time
from pathlib import Path
from typing import Optional, Dict, Tuple
from urllib.parse import quote, urljoin

# Try to import BeautifulSoup, but make it optional
try:
    from bs4 import BeautifulSoup
    HAS_BS4 = True
except ImportError:
    HAS_BS4 = False
    print("Note: Install beautifulsoup4 for better link extraction: pip install beautifulsoup4")

from config import LINK_SOURCES, TERM_CATEGORIES, KNOWN_TERMS, OUTPUT_SETTINGS


class LinkFetcher:
    """Fetches and validates links from academic sources."""

    def __init__(self, cache_enabled: bool = True):
        self.cache_enabled = cache_enabled
        self.cache_file = Path(__file__).parent / OUTPUT_SETTINGS.get("cache_file", "link_cache.json")
        self.cache = self._load_cache()
        self.session = requests.Session()
        self.session.headers.update({
            "User-Agent": "TheophysicsLexicon/1.0 (Academic Research Tool)"
        })

    def _load_cache(self) -> Dict:
        """Load cached links from file."""
        if self.cache_file.exists():
            try:
                with open(self.cache_file, 'r') as f:
                    return json.load(f)
            except:
                return {}
        return {}

    def _save_cache(self):
        """Save cache to file."""
        if self.cache_enabled:
            with open(self.cache_file, 'w') as f:
                json.dump(self.cache, f, indent=2)

    def _check_url_exists(self, url: str) -> bool:
        """Check if a URL returns a valid response."""
        try:
            response = self.session.head(url, timeout=5, allow_redirects=True)
            return response.status_code == 200
        except:
            try:
                # Some sites don't support HEAD, try GET
                response = self.session.get(url, timeout=5, allow_redirects=True)
                return response.status_code == 200
            except:
                return False

    def fetch_sep_link(self, term: str) -> Optional[str]:
        """
        Fetch link from Stanford Encyclopedia of Philosophy.
        SEP has clean URLs like: https://plato.stanford.edu/entries/einstein-philscience/
        """
        # Try direct entry URL first (most reliable)
        slug = term.lower().replace(" ", "-").replace("'", "")
        direct_url = f"https://plato.stanford.edu/entries/{slug}/"

        if self._check_url_exists(direct_url):
            return direct_url

        # Try common variations
        variations = [
            slug,
            slug.replace("-", ""),
            f"{slug}-philosophy",
            f"qt-{slug}",  # quantum terms
            f"physics-{slug}",
        ]

        for var in variations:
            url = f"https://plato.stanford.edu/entries/{var}/"
            if self._check_url_exists(url):
                return url

        # Try search if direct doesn't work
        if HAS_BS4:
            try:
                search_url = f"https://plato.stanford.edu/search/searcher.py?query={quote(term)}"
                response = self.session.get(search_url, timeout=10)
                if response.status_code == 200:
                    soup = BeautifulSoup(response.text, 'html.parser')
                    # Look for first result link
                    for link in soup.find_all('a', href=True):
                        href = link['href']
                        if '/entries/' in href:
                            return urljoin("https://plato.stanford.edu", href)
            except:
                pass

        return None

    def fetch_wikipedia_link(self, term: str) -> Optional[str]:
        """
        Fetch link from Wikipedia using their API.
        Returns the canonical article URL if found.
        """
        api_url = "https://en.wikipedia.org/w/api.php"

        # First, try to find the exact page
        params = {
            "action": "query",
            "titles": term,
            "format": "json",
            "redirects": 1
        }

        try:
            response = self.session.get(api_url, params=params, timeout=10)
            data = response.json()
            pages = data.get("query", {}).get("pages", {})

            for page_id, page_data in pages.items():
                if page_id != "-1":  # -1 means page not found
                    title = page_data.get("title", term)
                    return f"https://en.wikipedia.org/wiki/{quote(title.replace(' ', '_'))}"

            # If exact match fails, try search
            search_params = {
                "action": "opensearch",
                "search": term,
                "limit": 1,
                "format": "json"
            }

            response = self.session.get(api_url, params=search_params, timeout=10)
            data = response.json()

            if len(data) >= 4 and data[3]:  # URLs are in index 3
                return data[3][0]

        except Exception as e:
            print(f"Wikipedia API error: {e}")

        return None

    def fetch_scholarpedia_link(self, term: str) -> Optional[str]:
        """Fetch link from Scholarpedia."""
        slug = term.replace(" ", "_")
        url = f"http://www.scholarpedia.org/article/{slug}"

        if self._check_url_exists(url):
            return url

        return None

    def fetch_iep_link(self, term: str) -> Optional[str]:
        """Fetch link from Internet Encyclopedia of Philosophy."""
        slug = term.lower().replace(" ", "-").replace("'", "")
        url = f"https://iep.utm.edu/{slug}/"

        if self._check_url_exists(url):
            return url

        return None

    def fetch_philpapers_link(self, term: str) -> Optional[str]:
        """Fetch link from PhilPapers."""
        # PhilPapers uses search URLs
        search_url = f"https://philpapers.org/s/{quote(term)}"

        # Just return the search URL as PhilPapers doesn't have stable entry URLs
        # like SEP does
        return search_url

    def fetch_arxiv_link(self, term: str) -> Optional[str]:
        """Fetch link from arXiv."""
        # arXiv search URL
        search_url = f"https://arxiv.org/search/?query={quote(term)}&searchtype=all"
        return search_url

    def get_link(self, term: str, category: Optional[str] = None) -> Tuple[Optional[str], str]:
        """
        Get the best link for a term following the source hierarchy.

        Args:
            term: The term to look up
            category: Optional category hint (physicist, philosopher, concept, etc.)

        Returns:
            Tuple of (url, source_name) or (None, "")
        """
        # Check cache first
        cache_key = f"{term}:{category or 'any'}"
        if cache_key in self.cache:
            cached = self.cache[cache_key]
            return cached.get("url"), cached.get("source", "")

        # Check if it's a known term
        term_info = KNOWN_TERMS.get(term, {})
        if term_info:
            category = category or term_info.get("category")
            search_term = term_info.get("search_term", term_info.get("full_name", term))
        else:
            search_term = term

        # Determine source order based on category
        if category and category in TERM_CATEGORIES:
            preferred = TERM_CATEGORIES[category]["preferred_sources"]
            source_order = preferred + [s for s in ["SEP", "Scholarpedia", "IEP", "Wikipedia"] if s not in preferred]
        else:
            source_order = ["SEP", "Scholarpedia", "IEP", "Wikipedia"]

        # Try each source in order
        fetchers = {
            "SEP": (self.fetch_sep_link, "Stanford Encyclopedia of Philosophy"),
            "PhilPapers": (self.fetch_philpapers_link, "PhilPapers"),
            "Scholarpedia": (self.fetch_scholarpedia_link, "Scholarpedia"),
            "arXiv": (self.fetch_arxiv_link, "arXiv"),
            "IEP": (self.fetch_iep_link, "Internet Encyclopedia of Philosophy"),
            "Wikipedia": (self.fetch_wikipedia_link, "Wikipedia"),
        }

        for source in source_order:
            if source in fetchers:
                fetcher, source_name = fetchers[source]
                print(f"  Trying {source} for '{search_term}'...", end=" ")

                url = fetcher(search_term)

                if url:
                    print(f"Found!")
                    # Cache the result
                    self.cache[cache_key] = {"url": url, "source": source_name}
                    self._save_cache()
                    return url, source_name
                else:
                    print("Not found")

                # Small delay to be respectful to servers
                time.sleep(0.5)

        return None, ""

    def format_link(self, term: str, url: str, source: str, format: str = "markdown") -> str:
        """Format a link for output."""
        include_badge = OUTPUT_SETTINGS.get("include_source_badge", True)

        # Create source badge
        badge_map = {
            "Stanford Encyclopedia of Philosophy": "[SEP]",
            "Wikipedia": "[Wiki]",
            "Scholarpedia": "[Scholar]",
            "Internet Encyclopedia of Philosophy": "[IEP]",
            "PhilPapers": "[PhilPapers]",
            "arXiv": "[arXiv]",
        }
        badge = badge_map.get(source, f"[{source[:4]}]") if include_badge else ""

        if format == "markdown":
            if badge:
                return f"[{term}]({url}) {badge}"
            return f"[{term}]({url})"
        elif format == "html":
            if badge:
                return f'<a href="{url}" title="Source: {source}">{term}</a> <small>{badge}</small>'
            return f'<a href="{url}" title="Source: {source}">{term}</a>'
        else:  # plain
            if badge:
                return f"{term}: {url} {badge}"
            return f"{term}: {url}"


def main():
    """Test the link fetcher."""
    fetcher = LinkFetcher()

    test_terms = [
        ("Einstein", "physicist"),
        ("Chalmers", "philosopher"),
        ("Wave Function", "concept"),
        ("Copenhagen Interpretation", "theory"),
        ("Consciousness", "concept"),
        ("Logos", "theological"),
        ("Bell's Inequality", "theory"),
    ]

    print("=" * 60)
    print("THEOPHYSICS AUTO-LINKER TEST")
    print("=" * 60)

    for term, category in test_terms:
        print(f"\n--- Looking up: {term} ({category}) ---")
        url, source = fetcher.get_link(term, category)

        if url:
            formatted = fetcher.format_link(term, url, source)
            print(f"Result: {formatted}")
        else:
            print(f"No link found for '{term}'")

    print("\n" + "=" * 60)
    print("Test complete!")


if __name__ == "__main__":
    main()
