"""Gate 2: every grounded item's quote must appear verbatim in its source text.

    python pipeline/check_quotes.py [--apply]

Matching ignores case, whitespace and typographic quotes, nothing else, so
an invented or paraphrased "quote" fails. With --apply, failing items are
set to `flagged` (and a flag reason recorded); passing items keep their status.
"""

from __future__ import annotations

import argparse
import json
import sys
from functools import cache

from cseasy_pipeline.paths import CONTENT
from cseasy_pipeline.text import comparable

SOURCES = CONTENT / "sources"


@cache
def source_text(doc: str) -> str | None:
    path = SOURCES / f"{doc}.txt"
    return comparable(path.read_text(encoding="utf-8")) if path.exists() else None


def check(q: dict) -> str | None:
    """Failure reason, or None if the quote checks out."""
    text = source_text(q["source_doc"])
    if text is None:
        return f"unknown source_doc '{q['source_doc']}'"
    if comparable(q["quote"]) not in text:
        return "quote not found verbatim in source"
    return None


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--apply", action="store_true")
    args = parser.parse_args()

    failures = 0
    checked = 0
    for path in sorted((CONTENT / "cse").rglob("*.json")):
        items = json.loads(path.read_text(encoding="utf-8"))
        dirty = False
        for q in items:
            if q.get("method") != "llm-grounded" or q.get("status") == "rejected":
                continue
            checked += 1
            reason = check(q)
            if reason:
                failures += 1
                print(f"{q['id']}: {reason}\n    quote: {q['quote'][:120]!r}")
                if args.apply and q["status"] != "flagged":
                    q["status"] = "flagged"
                    q["flag_reason"] = f"quote check: {reason}"
                    dirty = True
        if dirty:
            path.write_text(json.dumps(items, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"{checked} grounded items checked, {failures} failed")
    sys.exit(1 if failures else 0)


if __name__ == "__main__":
    main()
