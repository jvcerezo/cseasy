"""Text normalization shared by source extraction and the quote matcher."""

from __future__ import annotations

import re

_QUOTES = str.maketrans({
    "‘": "'", "’": "'", "“": '"', "”": '"',
    "–": "-", "—": "-", "\xa0": " ",
})


def comparable(text: str) -> str:
    """Case-, whitespace- and typographic-quote-insensitive form for matching."""
    return re.sub(r"\s+", " ", text.translate(_QUOTES)).strip().lower()
