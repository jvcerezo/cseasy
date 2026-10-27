"""Expand hand-written (authored) questions into full schema records, in place.

    python pipeline/ingest.py

Authoring shortcut for the written sections (verbal, general_info, and the
written analytical topics): a new
item only needs topic, stem, choices, explanation and difficulty (plus
source, source_doc and quote when grounded). The CORRECT choice is written
FIRST and `answer` is left out; ingest shuffles the choices with a seed
derived from the stem and records where the key landed. Writing the key
first means its final position can't be biased by the author.

Items that already have an `id` are left untouched, so re-running is safe.
"""

from __future__ import annotations

import hashlib
import json
import random

from cseasy_pipeline.paths import CONTENT

WRITTEN_SECTIONS = {"verbal": "vrb", "general_info": "gen", "analytical": "ana"}
BOTH_LEVELS = ["professional", "subprofessional"]
# Analytical is a Professional-only subtest.
DEFAULT_LEVELS = {"analytical": ["professional"]}


def expand(q: dict, section: str, qid: str) -> dict:
    choices = list(q["choices"])
    correct = choices[0]
    seed = int(hashlib.sha256(q["stem"].encode()).hexdigest()[:8], 16)
    random.Random(seed).shuffle(choices)
    grounded = "quote" in q
    full = {
        "id": qid,
        "exam": "cse",
        "levels": q.get("levels", DEFAULT_LEVELS.get(section, BOTH_LEVELS)),
        "section": section,
        "topic": q["topic"],
        "stem": q["stem"],
        "choices": choices,
        "answer": choices.index(correct),
        "explanation": q["explanation"],
        "source": q.get("source"),
        "method": "llm-grounded" if grounded else "llm",
        "status": "draft",
        "difficulty": q.get("difficulty", 2),
    }
    if grounded:
        full["source_doc"] = q["source_doc"]
        full["quote"] = q["quote"]
    return full


def main() -> None:
    for section, prefix in WRITTEN_SECTIONS.items():
        for path in sorted((CONTENT / "cse" / section).glob("*.json")):
            items = json.loads(path.read_text(encoding="utf-8"))
            taken = {q["id"] for q in items if "id" in q}
            changed = 0
            for i, q in enumerate(items):
                if "id" in q:
                    continue
                n = 1
                while (qid := f"cse-{prefix}-{path.stem}-{n:03d}") in taken:
                    n += 1
                taken.add(qid)
                items[i] = expand(q, section, qid)
                changed += 1
            if changed:
                path.write_text(json.dumps(items, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
                print(f"{path.relative_to(CONTENT)}: expanded {changed}")


if __name__ == "__main__":
    main()
