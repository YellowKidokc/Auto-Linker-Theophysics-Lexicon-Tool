"""
Auto-Linker Configuration
Link hierarchy and source definitions for Theophysics Lexicon
"""

# Link Source Hierarchy (highest priority first)
# The system will try each source in order until it finds a valid link
LINK_SOURCES = {
    1: {
        "name": "Stanford Encyclopedia of Philosophy",
        "short": "SEP",
        "base_url": "https://plato.stanford.edu",
        "search_url": "https://plato.stanford.edu/search/searcher.py?query=",
        "entry_pattern": "https://plato.stanford.edu/entries/",
        "priority": 1,
        "types": ["philosophers", "concepts", "theories", "physics_philosophy"]
    },
    2: {
        "name": "PhilPapers",
        "short": "PhilPapers",
        "base_url": "https://philpapers.org",
        "search_url": "https://philpapers.org/s/",
        "priority": 2,
        "types": ["philosophers", "concepts", "papers"]
    },
    3: {
        "name": "Scholarpedia",
        "short": "Scholarpedia",
        "base_url": "http://www.scholarpedia.org",
        "search_url": "http://www.scholarpedia.org/article/",
        "priority": 3,
        "types": ["physics", "mathematics", "neuroscience", "concepts"]
    },
    4: {
        "name": "arXiv",
        "short": "arXiv",
        "base_url": "https://arxiv.org",
        "search_url": "https://arxiv.org/search/?query=",
        "priority": 4,
        "types": ["papers", "physics", "mathematics", "preprints"]
    },
    5: {
        "name": "Internet Encyclopedia of Philosophy",
        "short": "IEP",
        "base_url": "https://iep.utm.edu",
        "search_url": "https://iep.utm.edu/?s=",
        "priority": 5,
        "types": ["philosophers", "concepts", "theories"]
    },
    6: {
        "name": "Wikipedia",
        "short": "Wikipedia",
        "base_url": "https://en.wikipedia.org",
        "api_url": "https://en.wikipedia.org/w/api.php",
        "search_url": "https://en.wikipedia.org/wiki/",
        "priority": 6,
        "types": ["all"]  # Fallback for everything
    }
}

# Term Categories - helps determine which sources to try first
TERM_CATEGORIES = {
    "physicist": {
        "preferred_sources": ["SEP", "Scholarpedia", "Wikipedia"],
        "examples": ["Einstein", "Wheeler", "Bohr", "Feynman", "Penrose"]
    },
    "philosopher": {
        "preferred_sources": ["SEP", "PhilPapers", "IEP", "Wikipedia"],
        "examples": ["Chalmers", "Searle", "Aristotle", "Plato"]
    },
    "equation": {
        "preferred_sources": ["Scholarpedia", "Wikipedia"],
        "examples": ["Klein-Gordon", "Friedmann", "Schrodinger"]
    },
    "concept": {
        "preferred_sources": ["SEP", "Scholarpedia", "IEP", "Wikipedia"],
        "examples": ["Entropy", "Consciousness", "Wave Function"]
    },
    "theory": {
        "preferred_sources": ["SEP", "Scholarpedia", "Wikipedia"],
        "examples": ["Copenhagen Interpretation", "Many Worlds", "General Relativity"]
    },
    "theological": {
        "preferred_sources": ["SEP", "IEP", "Wikipedia"],
        "examples": ["Trinity", "Logos", "Pneuma", "Imago Dei"]
    }
}

# Known proper nouns from the Theophysics lexicon
# Pre-mapped for faster lookup
KNOWN_TERMS = {
    # Physicists
    "Wheeler": {"category": "physicist", "full_name": "John Archibald Wheeler"},
    "Einstein": {"category": "physicist", "full_name": "Albert Einstein"},
    "Bohr": {"category": "physicist", "full_name": "Niels Bohr"},
    "Penrose": {"category": "physicist", "full_name": "Roger Penrose"},
    "Von Neumann": {"category": "physicist", "full_name": "John von Neumann"},
    "Zurek": {"category": "physicist", "full_name": "Wojciech Zurek"},
    "Zeh": {"category": "physicist", "full_name": "H. Dieter Zeh"},
    "Hawking": {"category": "physicist", "full_name": "Stephen Hawking"},
    "Feynman": {"category": "physicist", "full_name": "Richard Feynman"},
    "Landauer": {"category": "physicist", "full_name": "Rolf Landauer"},
    "Bell": {"category": "physicist", "full_name": "John Stewart Bell"},

    # Philosophers of Mind
    "Chalmers": {"category": "philosopher", "full_name": "David Chalmers"},
    "Searle": {"category": "philosopher", "full_name": "John Searle"},
    "Turing": {"category": "physicist", "full_name": "Alan Turing"},

    # Equations & Principles
    "Klein-Gordon Equation": {"category": "equation", "search_term": "Klein-Gordon equation"},
    "Friedmann Equations": {"category": "equation", "search_term": "Friedmann equations"},
    "E=mc²": {"category": "equation", "search_term": "mass-energy equivalence"},
    "Schrödinger Equation": {"category": "equation", "search_term": "Schrodinger equation"},

    # Theories & Interpretations
    "Copenhagen Interpretation": {"category": "theory", "search_term": "Copenhagen interpretation quantum mechanics"},
    "Many Worlds Interpretation": {"category": "theory", "search_term": "many-worlds interpretation"},
    "General Relativity": {"category": "theory", "search_term": "general relativity"},
    "Bell's Inequality": {"category": "theory", "search_term": "Bell inequality"},
    "EPR Paradox": {"category": "theory", "search_term": "EPR paradox"},

    # Concepts
    "Wave Function": {"category": "concept", "search_term": "wave function"},
    "Quantum Entanglement": {"category": "concept", "search_term": "quantum entanglement"},
    "Consciousness": {"category": "concept", "search_term": "consciousness"},
    "Hard Problem of Consciousness": {"category": "concept", "search_term": "hard problem of consciousness"},
    "Holographic Principle": {"category": "concept", "search_term": "holographic principle"},
    "Entropy": {"category": "concept", "search_term": "entropy"},
    "Negentropy": {"category": "concept", "search_term": "negentropy"},

    # Theological/Philosophical
    "Logos": {"category": "theological", "search_term": "Logos philosophy"},
    "Trinity": {"category": "theological", "search_term": "Trinity Christianity"},
    "Imago Dei": {"category": "theological", "search_term": "Imago Dei"},
    "Perichoresis": {"category": "theological", "search_term": "Perichoresis"},
}

# Glossary terms that can use Wikipedia directly
# These are definitional terms, not proper nouns
GLOSSARY_TERMS = [
    "Coherence",
    "Decoherence",
    "Entropy",
    "Negentropy",
    "Wave Function",
    "Quantum State",
    "Superposition",
    "Entanglement",
    "Measurement Problem",
    "Observer Effect",
    "Thermodynamics",
    "Information Theory",
    "Spacetime",
    "Curvature",
    "Dark Energy",
    "Cosmological Constant",
]

# Output settings
OUTPUT_SETTINGS = {
    "link_format": "markdown",  # markdown, html, or plain
    "include_source_badge": True,  # Add [SEP] or [Wiki] after links
    "cache_links": True,  # Cache successful lookups
    "cache_file": "link_cache.json"
}
