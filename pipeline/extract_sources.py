"""Turn downloaded law pages (content/sources/raw/*.html) into plain text.

    python pipeline/extract_sources.py

The .txt files are what grounded questions quote from and what the quote
matcher checks against, so they must stay verbatim apart from whitespace
and typographic-quote normalization.
"""

from __future__ import annotations

import html
import re
from html.parser import HTMLParser

from cseasy_pipeline.paths import CONTENT

SOURCES = CONTENT / "sources"
RAW = SOURCES / "raw"

SKIP_TAGS = {"script", "style", "noscript", "title", "nav", "footer", "header", "form"}
BLOCK_TAGS = {"p", "div", "br", "li", "h1", "h2", "h3", "h4", "h5", "h6", "tr", "blockquote", "center", "table"}


class _TextExtractor(HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.parts: list[str] = []
        self._skip = 0

    def handle_starttag(self, tag, attrs):
        if tag in SKIP_TAGS:
            self._skip += 1
        elif tag in BLOCK_TAGS:
            self.parts.append("\n")

    def handle_endtag(self, tag):
        if tag in SKIP_TAGS and self._skip:
            self._skip -= 1
        elif tag in BLOCK_TAGS:
            self.parts.append("\n")

    def handle_data(self, data):
        if not self._skip:
            self.parts.append(data)


def normalize(text: str) -> str:
    """Whitespace and quote normalization shared with the quote matcher."""
    text = html.unescape(text)
    text = (
        text.replace("‘", "'").replace("’", "'")
        .replace("“", '"').replace("”", '"')
        .replace("–", "-").replace("—", "-").replace("\xa0", " ")
    )
    # lawphil.net injects watermark tokens mid-sentence (e.g. "subsidiaries.lawphi1.net").
    text = re.sub(r"lawphi[l1]\.(?:net|com)", " ", text)
    return re.sub(r"[ \t\r\f\v]+", " ", text)


def decode(raw: bytes) -> str:
    try:
        return raw.decode("utf-8")
    except UnicodeDecodeError:
        return raw.decode("cp1252", errors="replace")


def main() -> None:
    for path in sorted(RAW.glob("*.html")):
        parser = _TextExtractor()
        parser.feed(decode(path.read_bytes()))
        text = normalize("".join(parser.parts))
        lines = [line.strip() for line in text.split("\n")]
        text = re.sub(r"\n{3,}", "\n\n", "\n".join(lines)).strip() + "\n"
        out = SOURCES / f"{path.stem}.txt"
        out.write_text(text, encoding="utf-8")
        print(f"{out.name:<26} {len(text):>8} chars")


if __name__ == "__main__":
    main()
