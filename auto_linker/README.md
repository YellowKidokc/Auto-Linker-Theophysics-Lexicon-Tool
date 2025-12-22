# Theophysics Auto-Linker

Automatically links proper nouns, scientific terms, and glossary terms to high-quality academic sources.

## The Link Hierarchy

When the auto-linker finds a term, it tries sources in this order:

| Priority | Source | Best For |
|----------|--------|----------|
| 1 | Stanford Encyclopedia of Philosophy (SEP) | Philosophers, concepts, theories |
| 2 | PhilPapers | Philosophy papers and topics |
| 3 | Scholarpedia | Physics, mathematics, neuroscience |
| 4 | arXiv | Preprints, cutting-edge research |
| 5 | Internet Encyclopedia of Philosophy (IEP) | Philosophy (more accessible) |
| 6 | Wikipedia | Fallback for everything |

**Wikipedia is the fallback, not the first choice.**

## Installation

```bash
cd auto_linker
pip install -r requirements.txt
```

## Usage

### Scan a file for terms
```bash
python auto_linker.py scan paper.md
python auto_linker.py scan paper.md --json  # JSON output
```

### Look up a single term
```bash
python auto_linker.py lookup "Einstein"
python auto_linker.py lookup "Consciousness" -c concept
python auto_linker.py lookup "Copenhagen Interpretation" -c theory
```

### Generate linked version of a file
```bash
python auto_linker.py link paper.md                    # Print to stdout
python auto_linker.py link paper.md -o paper_linked.md # Save to file
python auto_linker.py link paper.md --all              # Link ALL found terms
```

### Generate link index for directory
```bash
python auto_linker.py index ./papers/
python auto_linker.py index ./papers/ -o ./output/
```

## How It Works

### 1. Term Detection

The scanner identifies:

- **Known Terms**: Pre-defined in `config.py` (Einstein, Chalmers, Klein-Gordon, etc.)
- **Glossary Terms**: Standard physics/philosophy vocabulary
- **Proper Nouns**: Capitalized words not at sentence starts
- **Title Case Phrases**: Multi-word terms like "Copenhagen Interpretation"

### 2. Category Detection

Each term gets a category hint:

| Category | Examples |
|----------|----------|
| `physicist` | Einstein, Wheeler, Feynman |
| `philosopher` | Chalmers, Searle, Aristotle |
| `equation` | Klein-Gordon, Friedmann, E=mc² |
| `concept` | Entropy, Consciousness, Wave Function |
| `theory` | Copenhagen Interpretation, Many Worlds |
| `theological` | Logos, Trinity, Imago Dei |

### 3. Link Lookup

For each term, the system:

1. Checks if it's a known term with category
2. Determines preferred sources for that category
3. Tries each source in order until a valid link is found
4. Caches successful lookups for speed

### 4. Output

Links are formatted as:
```markdown
[Einstein](https://plato.stanford.edu/entries/einstein-philscience/) [SEP]
```

The `[SEP]` badge shows the source. Can be disabled in config.

## Configuration

Edit `config.py` to:

- Add known terms
- Modify source hierarchy
- Add glossary terms
- Change output format

### Adding Known Terms

```python
KNOWN_TERMS = {
    "Penrose": {
        "category": "physicist",
        "full_name": "Roger Penrose"
    },
    # ...
}
```

### Adding Glossary Terms

```python
GLOSSARY_TERMS = [
    "Wave Function",
    "Quantum State",
    # ...
]
```

## Example Output

Input:
```markdown
Einstein demonstrated that matter and energy are equivalent.
The Copenhagen Interpretation remains controversial.
```

Output:
```markdown
[Einstein](https://plato.stanford.edu/entries/einstein-philscience/) [SEP] demonstrated
that matter and energy are equivalent.
The [Copenhagen Interpretation](https://plato.stanford.edu/entries/qm-copenhagen/) [SEP]
remains controversial.
```

## Caching

Successful lookups are cached in `link_cache.json` to:
- Speed up repeated runs
- Reduce API calls
- Work offline for cached terms

Clear the cache by deleting `link_cache.json`.

## Glossary vs Paper Terms

| Type | Wikipedia OK? | Preferred Sources |
|------|---------------|-------------------|
| Glossary terms | Yes | Wikipedia fine for definitions |
| Proper nouns | Last resort | SEP, Scholarpedia first |
| Equations | Last resort | Scholarpedia, Wikipedia |
| Philosophers | Last resort | SEP, PhilPapers, IEP |

## Files

```
auto_linker/
├── auto_linker.py    # Main CLI tool
├── config.py         # Configuration and known terms
├── link_fetcher.py   # Fetches links from sources
├── term_scanner.py   # Scans text for terms
├── requirements.txt  # Python dependencies
├── link_cache.json   # Cached lookups (generated)
└── README.md         # This file
```
