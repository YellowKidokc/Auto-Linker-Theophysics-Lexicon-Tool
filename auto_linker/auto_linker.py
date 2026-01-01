#!/usr/bin/env python3
"""
Theophysics Auto-Linker
Automatically links proper nouns and terms to high-quality academic sources.

Hierarchy:
1. Stanford Encyclopedia of Philosophy (SEP)
2. PhilPapers
3. Scholarpedia
4. arXiv
5. Internet Encyclopedia of Philosophy (IEP)
6. Wikipedia (fallback)

Usage:
    python auto_linker.py scan <file.md>           # Scan and show terms
    python auto_linker.py link <file.md>           # Generate linked version
    python auto_linker.py lookup "Term Name"       # Look up a single term
    python auto_linker.py index <directory>        # Generate link index for directory
"""

import sys
import argparse
import json
from pathlib import Path
from typing import Dict, List, Optional
from dataclasses import asdict

from config import KNOWN_TERMS, GLOSSARY_TERMS, OUTPUT_SETTINGS
from term_scanner import TermScanner, FoundTerm
from link_fetcher import LinkFetcher


class AutoLinker:
    """Main auto-linker class that ties scanning and fetching together."""

    def __init__(self, verbose: bool = True):
        self.scanner = TermScanner()
        self.fetcher = LinkFetcher()
        self.verbose = verbose

    def log(self, message: str):
        """Print if verbose mode is on."""
        if self.verbose:
            print(message)

    def scan_file(self, file_path: Path) -> List[FoundTerm]:
        """Scan a file and return found terms."""
        self.log(f"\nScanning: {file_path}")
        terms = self.scanner.scan_file(file_path)
        self.log(f"Found {len(terms)} terms")
        return terms

    def lookup_term(self, term: str, category: Optional[str] = None) -> Dict:
        """Look up a single term and return link info."""
        self.log(f"\nLooking up: {term}" + (f" ({category})" if category else ""))

        url, source = self.fetcher.get_link(term, category)

        result = {
            "term": term,
            "category": category,
            "url": url,
            "source": source,
            "found": url is not None
        }

        if url:
            formatted = self.fetcher.format_link(term, url, source)
            result["markdown"] = formatted
            self.log(f"Found: {formatted}")
        else:
            self.log(f"No link found for '{term}'")

        return result

    def generate_linked_text(self, text: str, link_all: bool = False) -> str:
        """
        Take text and return it with terms linked.

        Args:
            text: The source text
            link_all: If True, link all found terms. If False, only link known terms.
        """
        terms = self.scanner.scan_text(text)
        self.log(f"Found {len(terms)} potential terms to link")

        # Sort by position (reverse) so we can replace without messing up indices
        # We need to find the actual positions for replacement
        import re

        replacements = []

        for term_info in terms:
            term = term_info.term

            # Skip unknown terms unless link_all is set
            if not link_all and term_info.category == "unknown":
                continue

            # Look up the link
            url, source = self.fetcher.get_link(term, term_info.category)

            if url:
                # Find all occurrences of this term in text
                pattern = re.compile(r'\b' + re.escape(term) + r'\b')
                for match in pattern.finditer(text):
                    # Don't replace if already in a markdown link
                    before = text[max(0, match.start() - 2):match.start()]
                    after = text[match.end():min(len(text), match.end() + 2)]
                    if before.endswith('[') or after.startswith(']('):
                        continue

                    replacements.append({
                        "start": match.start(),
                        "end": match.end(),
                        "original": term,
                        "replacement": self.fetcher.format_link(term, url, source, "markdown")
                    })
                    break  # Only replace first occurrence

        # Sort by position (reverse) and apply replacements
        replacements.sort(key=lambda x: x["start"], reverse=True)

        result = text
        for rep in replacements:
            result = result[:rep["start"]] + rep["replacement"] + result[rep["end"]:]

        return result

    def generate_link_index(self, file_path: Path) -> Dict:
        """
        Generate a link index for a file - a JSON mapping of terms to their links.
        """
        terms = self.scan_file(file_path)

        index = {
            "source_file": str(file_path),
            "total_terms": len(terms),
            "linked_terms": 0,
            "terms": {}
        }

        for term_info in terms:
            term = term_info.term

            # Skip if already in index
            if term in index["terms"]:
                continue

            url, source = self.fetcher.get_link(term, term_info.category)

            if url:
                index["terms"][term] = {
                    "url": url,
                    "source": source,
                    "category": term_info.category,
                    "is_proper_noun": term_info.is_proper_noun,
                    "is_glossary_term": term_info.is_glossary_term
                }
                index["linked_terms"] += 1
            else:
                index["terms"][term] = {
                    "url": None,
                    "source": None,
                    "category": term_info.category,
                    "not_found": True
                }

        return index

    def process_directory(self, dir_path: Path, output_dir: Optional[Path] = None) -> Dict:
        """
        Process all markdown files in a directory.
        Returns a master index of all terms found.
        """
        master_index = {
            "source_directory": str(dir_path),
            "files_processed": 0,
            "total_terms": 0,
            "linked_terms": 0,
            "terms": {}
        }

        md_files = list(dir_path.rglob("*.md"))
        self.log(f"\nProcessing {len(md_files)} markdown files...")

        for file_path in md_files:
            self.log(f"\n--- {file_path.name} ---")
            file_index = self.generate_link_index(file_path)

            master_index["files_processed"] += 1
            master_index["total_terms"] += file_index["total_terms"]
            master_index["linked_terms"] += file_index["linked_terms"]

            # Merge terms
            for term, info in file_index["terms"].items():
                if term not in master_index["terms"]:
                    master_index["terms"][term] = info
                    master_index["terms"][term]["found_in"] = [str(file_path)]
                else:
                    if "found_in" in master_index["terms"][term]:
                        master_index["terms"][term]["found_in"].append(str(file_path))

        if output_dir:
            output_file = output_dir / "link_index.json"
            with open(output_file, 'w', encoding='utf-8') as f:
                json.dump(master_index, f, indent=2)
            self.log(f"\nIndex saved to: {output_file}")

        return master_index


def main():
    parser = argparse.ArgumentParser(
        description="Theophysics Auto-Linker - Link terms to academic sources"
    )

    subparsers = parser.add_subparsers(dest="command", help="Commands")

    # Scan command
    scan_parser = subparsers.add_parser("scan", help="Scan a file for terms")
    scan_parser.add_argument("file", type=Path, help="File to scan")
    scan_parser.add_argument("--json", action="store_true", help="Output as JSON")

    # Link command
    link_parser = subparsers.add_parser("link", help="Generate linked version of file")
    link_parser.add_argument("file", type=Path, help="File to process")
    link_parser.add_argument("-o", "--output", type=Path, help="Output file")
    link_parser.add_argument("--all", action="store_true", help="Link all found terms")

    # Lookup command
    lookup_parser = subparsers.add_parser("lookup", help="Look up a single term")
    lookup_parser.add_argument("term", help="Term to look up")
    lookup_parser.add_argument("-c", "--category", help="Term category hint")

    # Index command
    index_parser = subparsers.add_parser("index", help="Generate link index")
    index_parser.add_argument("path", type=Path, help="File or directory to index")
    index_parser.add_argument("-o", "--output", type=Path, help="Output directory")

    args = parser.parse_args()

    if not args.command:
        parser.print_help()
        return

    linker = AutoLinker()

    if args.command == "scan":
        terms = linker.scan_file(args.file)

        if args.json:
            output = [asdict(t) for t in terms]
            print(json.dumps(output, indent=2))
        else:
            print(f"\n{'='*60}")
            print(f"TERMS FOUND IN: {args.file.name}")
            print(f"{'='*60}\n")

            for term in terms:
                print(f"  [{term.category}] {term.term}")
                print(f"    Line {term.line_number}")
                print(f"    Proper noun: {term.is_proper_noun}")
                print()

    elif args.command == "link":
        with open(args.file, 'r', encoding='utf-8') as f:
            text = f.read()

        linked_text = linker.generate_linked_text(text, link_all=args.all)

        if args.output:
            with open(args.output, 'w', encoding='utf-8') as f:
                f.write(linked_text)
            print(f"Linked version saved to: {args.output}")
        else:
            print(linked_text)

    elif args.command == "lookup":
        result = linker.lookup_term(args.term, args.category)
        print(json.dumps(result, indent=2))

    elif args.command == "index":
        path = args.path

        if path.is_file():
            index = linker.generate_link_index(path)
        else:
            index = linker.process_directory(path, args.output)

        print(f"\n{'='*60}")
        print("LINK INDEX SUMMARY")
        print(f"{'='*60}")
        print(f"Total terms found: {index.get('total_terms', len(index.get('terms', {})))}")
        print(f"Successfully linked: {index.get('linked_terms', 0)}")
        print()

        # Show some examples
        terms = index.get("terms", {})
        linked = [(k, v) for k, v in terms.items() if v.get("url")][:10]

        if linked:
            print("Sample linked terms:")
            for term, info in linked:
                print(f"  {term}: {info.get('source')}")
                print(f"    {info.get('url')}")


if __name__ == "__main__":
    main()
