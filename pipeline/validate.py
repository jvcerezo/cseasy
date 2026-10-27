"""Check every question under content/ against the schema.

    python pipeline/validate.py

Exits non-zero on any problem so it can gate the build and CI.
"""

from __future__ import annotations

import json
import sys
from collections import Counter

from cseasy_pipeline.paths import CONTENT
from cseasy_pipeline.schema import validate_question


def load_all() -> list[dict]:
    questions: list[dict] = []
    for path in sorted(CONTENT.rglob("*.json")):
        data = json.loads(path.read_text(encoding="utf-8"))
        if not isinstance(data, list):
            raise ValueError(f"{path}: expected a JSON list of questions")
        questions.extend(data)
    return questions


def problems(questions: list[dict]) -> list[str]:
    errors = [e for q in questions for e in validate_question(q)]
    ids = Counter(q.get("id") for q in questions)
    errors += [f"duplicate id {i} ({n}x)" for i, n in ids.items() if n > 1]
    stems = Counter(q.get("stem", "").strip().lower() for q in questions)
    errors += [f"duplicate stem: {s[:60]!r}" for s, n in stems.items() if n > 1]
    return errors


def main() -> None:
    questions = load_all()
    errors = problems(questions)
    for e in errors:
        print(e)
    by_status = Counter(q.get("status") for q in questions)
    print(f"{len(questions)} questions, {dict(by_status)}, {len(errors)} problems")
    sys.exit(1 if errors else 0)


if __name__ == "__main__":
    main()
