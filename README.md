# AI-HUB-AHK

A collection of AI-powered tools and automation utilities.

## Features

### Auto-Linker (Theophysics Lexicon Tool)

Automatically links proper nouns, scientific terms, and concepts to high-quality academic sources.

**Link Hierarchy** (tries in order):
1. Stanford Encyclopedia of Philosophy (SEP)
2. PhilPapers
3. Scholarpedia
4. arXiv
5. Internet Encyclopedia of Philosophy (IEP)
6. Wikipedia (fallback)

**Usage:**
```bash
cd auto_linker
pip install -r requirements.txt

# Look up a term
python auto_linker.py lookup "Einstein"

# Scan a file for linkable terms
python auto_linker.py scan paper.md

# Generate linked version
python auto_linker.py link paper.md -o paper_linked.md
```

See [auto_linker/README.md](auto_linker/README.md) for full documentation.

## Project Structure

```
AI-HUB-AHK/
├── auto_linker/          # Auto-linking tool for academic sources
│   ├── auto_linker.py    # Main CLI
│   ├── config.py         # Configuration
│   ├── link_fetcher.py   # Source fetching
│   ├── term_scanner.py   # Term detection
│   └── requirements.txt
└── README.md
```

## License

MIT
