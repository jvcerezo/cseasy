"""Regenerate the computed sections (content/cse/<section>/*.json) from code.

    python pipeline/generate.py [--per-topic 40] [--section numerical]

Output is deterministic (each topic has a fixed seed), so re-running only
produces a diff when a generator changes.
"""

from __future__ import annotations

import argparse
import json
import random
from typing import Callable

from cseasy_pipeline.generators import analytical, clerical, numerical
from cseasy_pipeline.paths import CONTENT
from cseasy_pipeline.schema import validate_question

# section -> (id prefix, generators)
SECTIONS: dict[str, tuple[str, dict[str, Callable[[random.Random], dict]]]] = {
    "numerical": ("num", numerical.GENERATORS),
    "analytical": ("ana", analytical.GENERATORS),
    "clerical": ("cle", clerical.GENERATORS),
}


def dedup_key(q: dict) -> str:
    # Data-interpretation items share stems and differ only in their table.
    return q["stem"] + json.dumps(q.get("table"), sort_keys=True)


def generate_topic(section: str, topic: str, count: int) -> list[dict]:
    prefix, generators = SECTIONS[section]
    rng = random.Random(f"cse-{section}-{topic}")
    seen: set[str] = set()
    questions: list[dict] = []
    attempts = 0
    while len(questions) < count:
        attempts += 1
        if attempts > count * 50:
            raise RuntimeError(f"{topic}: only {len(questions)} unique questions after {attempts} attempts")
        q = generators[topic](rng)
        key = dedup_key(q)
        if key in seen:
            continue
        seen.add(key)
        q = {"id": f"cse-{prefix}-{topic}-{len(questions) + 1:03d}", **q}
        errors = validate_question(q)
        if errors:
            raise ValueError("\n".join(errors))
        questions.append(q)
    return questions


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--per-topic", type=int, default=40)
    parser.add_argument("--section", choices=sorted(SECTIONS), action="append")
    args = parser.parse_args()

    total = 0
    for section in args.section or SECTIONS:
        out_dir = CONTENT / "cse" / section
        out_dir.mkdir(parents=True, exist_ok=True)
        for topic in SECTIONS[section][1]:
            questions = generate_topic(section, topic, args.per_topic)
            path = out_dir / f"{topic}.json"
            path.write_text(json.dumps(questions, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
            total += len(questions)
            print(f"{section:<11} {topic:<24} {len(questions):>4}")
    print(f"{'total':<36} {total:>4}")


if __name__ == "__main__":
    main()
