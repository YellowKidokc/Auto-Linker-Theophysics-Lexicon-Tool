"""
Term Scanner - Scans markdown files for proper nouns, equations, and terms
that should be linked to external sources.
"""

import re
from pathlib import Path
from typing import List, Dict, Set, Tuple, Optional
from dataclasses import dataclass
from config import KNOWN_TERMS, GLOSSARY_TERMS, TERM_CATEGORIES


@dataclass
class FoundTerm:
    """Represents a term found in a document."""
    term: str
    category: str
    line_number: int
    context: str  # Surrounding text
    is_proper_noun: bool
    is_glossary_term: bool
    needs_linking: bool = True


class TermScanner:
    """Scans text for proper nouns and terms that should be linked."""

    def __init__(self):
        # Compile patterns for efficiency
        self._compile_patterns()

    def _compile_patterns(self):
        """Compile regex patterns for term detection."""

        # Pattern for capitalized words (potential proper nouns)
        # Matches: Einstein, Von Neumann, Klein-Gordon
        self.proper_noun_pattern = re.compile(
            r'\b([A-Z][a-z]+(?:[-\s][A-Z][a-z]+)*)\b'
        )

        # Pattern for equations like E=mc², F=ma, etc.
        self.equation_pattern = re.compile(
            r'\b([A-Z]\s*=\s*[a-zA-Z0-9²³⁴]+)\b'
        )

        # Pattern for Greek letters often used in physics
        self.greek_pattern = re.compile(
            r'[χψφλσΨΦΛ]'
        )

        # Pattern for academic terms (Title Case phrases)
        self.title_case_pattern = re.compile(
            r'\b([A-Z][a-z]+(?:\s+[A-Z][a-z]+)+)\b'
        )

        # Already linked pattern - don't re-link
        self.already_linked_pattern = re.compile(
            r'\[([^\]]+)\]\([^)]+\)'
        )

        # Build known terms pattern for fast matching
        known_terms_escaped = [re.escape(t) for t in KNOWN_TERMS.keys()]
        if known_terms_escaped:
            self.known_terms_pattern = re.compile(
                r'\b(' + '|'.join(known_terms_escaped) + r')\b',
                re.IGNORECASE
            )
        else:
            self.known_terms_pattern = None

        # Glossary terms pattern
        glossary_escaped = [re.escape(t) for t in GLOSSARY_TERMS]
        if glossary_escaped:
            self.glossary_pattern = re.compile(
                r'\b(' + '|'.join(glossary_escaped) + r')\b',
                re.IGNORECASE
            )
        else:
            self.glossary_pattern = None

    def _get_context(self, text: str, match_start: int, match_end: int, context_chars: int = 50) -> str:
        """Get surrounding context for a match."""
        start = max(0, match_start - context_chars)
        end = min(len(text), match_end + context_chars)
        context = text[start:end]

        if start > 0:
            context = "..." + context
        if end < len(text):
            context = context + "..."

        return context.replace("\n", " ")

    def _is_sentence_start(self, text: str, match_start: int) -> bool:
        """Check if the match is at the start of a sentence."""
        if match_start == 0:
            return True

        # Look back for sentence-ending punctuation
        before = text[max(0, match_start - 3):match_start].strip()
        if before and before[-1] in '.!?':
            return True

        # Check for newline (often indicates new sentence in markdown)
        if match_start > 0 and text[match_start - 1] == '\n':
            return True

        return False

    def _extract_already_linked(self, text: str) -> Set[str]:
        """Find terms that are already linked in the text."""
        linked = set()
        for match in self.already_linked_pattern.finditer(text):
            linked.add(match.group(1).lower())
        return linked

    def scan_text(self, text: str) -> List[FoundTerm]:
        """
        Scan text for terms that should be linked.

        Returns a list of FoundTerm objects.
        """
        found_terms: List[FoundTerm] = []
        seen_terms: Set[str] = set()  # Avoid duplicates

        # Get already linked terms
        already_linked = self._extract_already_linked(text)

        # Split into lines for line number tracking
        lines = text.split('\n')
        current_pos = 0
        line_starts = [0]
        for line in lines:
            current_pos += len(line) + 1
            line_starts.append(current_pos)

        def get_line_number(pos: int) -> int:
            for i, start in enumerate(line_starts):
                if start > pos:
                    return i
            return len(lines)

        # 1. First, find known terms (highest priority)
        if self.known_terms_pattern:
            for match in self.known_terms_pattern.finditer(text):
                term = match.group(1)
                normalized = term.lower()

                if normalized in seen_terms or normalized in already_linked:
                    continue

                # Find the canonical form from KNOWN_TERMS
                canonical = None
                for known in KNOWN_TERMS.keys():
                    if known.lower() == normalized:
                        canonical = known
                        break

                if canonical:
                    term_info = KNOWN_TERMS[canonical]
                    found_terms.append(FoundTerm(
                        term=canonical,
                        category=term_info.get("category", "unknown"),
                        line_number=get_line_number(match.start()),
                        context=self._get_context(text, match.start(), match.end()),
                        is_proper_noun=True,
                        is_glossary_term=False
                    ))
                    seen_terms.add(normalized)

        # 2. Find glossary terms
        if self.glossary_pattern:
            for match in self.glossary_pattern.finditer(text):
                term = match.group(1)
                normalized = term.lower()

                if normalized in seen_terms or normalized in already_linked:
                    continue

                # Find canonical form
                canonical = None
                for gloss in GLOSSARY_TERMS:
                    if gloss.lower() == normalized:
                        canonical = gloss
                        break

                if canonical:
                    found_terms.append(FoundTerm(
                        term=canonical,
                        category="concept",
                        line_number=get_line_number(match.start()),
                        context=self._get_context(text, match.start(), match.end()),
                        is_proper_noun=False,
                        is_glossary_term=True
                    ))
                    seen_terms.add(normalized)

        # 3. Find potential proper nouns (capitalized words not at sentence start)
        for match in self.proper_noun_pattern.finditer(text):
            term = match.group(1)
            normalized = term.lower()

            if normalized in seen_terms or normalized in already_linked:
                continue

            # Skip if at sentence start (might just be regular capitalization)
            if self._is_sentence_start(text, match.start()):
                continue

            # Skip common words that are often capitalized
            skip_words = {'the', 'a', 'an', 'in', 'on', 'at', 'to', 'for', 'of',
                         'and', 'or', 'but', 'is', 'are', 'was', 'were', 'be',
                         'this', 'that', 'these', 'those', 'it', 'its'}
            if normalized in skip_words:
                continue

            # Skip very short words
            if len(term) < 3:
                continue

            # This looks like a proper noun worth investigating
            found_terms.append(FoundTerm(
                term=term,
                category="unknown",
                line_number=get_line_number(match.start()),
                context=self._get_context(text, match.start(), match.end()),
                is_proper_noun=True,
                is_glossary_term=False,
                needs_linking=True  # Will be verified during link lookup
            ))
            seen_terms.add(normalized)

        # 4. Find Title Case phrases (potential theory/concept names)
        for match in self.title_case_pattern.finditer(text):
            term = match.group(1)
            normalized = term.lower()

            if normalized in seen_terms or normalized in already_linked:
                continue

            # Skip if it's at the start of a sentence
            if self._is_sentence_start(text, match.start()):
                continue

            # This could be a theory or concept name
            found_terms.append(FoundTerm(
                term=term,
                category="theory",
                line_number=get_line_number(match.start()),
                context=self._get_context(text, match.start(), match.end()),
                is_proper_noun=True,
                is_glossary_term=False
            ))
            seen_terms.add(normalized)

        return found_terms

    def scan_file(self, file_path: Path) -> List[FoundTerm]:
        """Scan a markdown file for terms."""
        if not file_path.exists():
            raise FileNotFoundError(f"File not found: {file_path}")

        with open(file_path, 'r', encoding='utf-8') as f:
            text = f.read()

        return self.scan_text(text)

    def scan_directory(self, dir_path: Path, pattern: str = "*.md") -> Dict[Path, List[FoundTerm]]:
        """Scan all markdown files in a directory."""
        results = {}

        for file_path in dir_path.rglob(pattern):
            try:
                terms = self.scan_file(file_path)
                if terms:
                    results[file_path] = terms
            except Exception as e:
                print(f"Error scanning {file_path}: {e}")

        return results


def main():
    """Test the term scanner."""
    scanner = TermScanner()

    test_text = """
    # The Theophysics Framework

    As Einstein demonstrated with his famous equation E=mc², matter and energy
    are fundamentally interchangeable. Wheeler later proposed the concept of
    "it from bit," suggesting that information is primary.

    The Copenhagen Interpretation, developed by Bohr and Heisenberg, remains
    controversial. Chalmers' Hard Problem of Consciousness challenges purely
    physical explanations.

    Key concepts include:
    - Wave Function collapse
    - Quantum Entanglement
    - The Measurement Problem

    The Logos principle connects to John 1:1, where the divine Word creates reality.
    """

    print("=" * 60)
    print("TERM SCANNER TEST")
    print("=" * 60)

    terms = scanner.scan_text(test_text)

    print(f"\nFound {len(terms)} terms:\n")

    for term in terms:
        print(f"  [{term.category}] {term.term}")
        print(f"    Line {term.line_number}: {term.context[:60]}...")
        print(f"    Proper noun: {term.is_proper_noun}, Glossary: {term.is_glossary_term}")
        print()


if __name__ == "__main__":
    main()
