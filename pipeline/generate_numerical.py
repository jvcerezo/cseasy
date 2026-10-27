"""Regenerate content/cse/numerical/*.json from the code generators.

    python pipeline/generate_numerical.py [--per-topic 40]

Output is deterministic (each topic has a fixed seed), so re-running only
produces a diff when a generator changes.
"""

from __future__ import annotations

import argparse
import json
import random

from cseasy_pipeline.generators.numerical import GENERATORS
from cseasy_pipeline.paths import CONTENT
from cseasy_pipeline.schema import validate_question


def generate_topic(topic: str, count: int) -> list[dict]:
    rng = random.Random(f"cse-numerical-{topic}")
    gen = GENERATORS[topic]
    seen: set[str] = set()
    questions: list[dict] = []
    attempts = 0
    while len(questions) < count:
        attempts += 1
        if attempts > count * 50:
            raise RuntimeError(f"{topic}: only {len(questions)} unique questions after {attempts} attempts")
        q = gen(rng)
        if q["stem"] in seen:
            continue
        seen.add(q["stem"])
        q = {"id": f"cse-num-{topic}-{len(questions) + 1:03d}", **q}
        errors = validate_question(q)
        if errors:
            raise ValueError("\n".join(errors))
        questions.append(q)
    return questions


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--per-topic", type=int, default=40)
    args = parser.parse_args()

    out_dir = CONTENT / "cse" / "numerical"
    out_dir.mkdir(parents=True, exist_ok=True)
    total = 0
    for topic in GENERATORS:
        questions = generate_topic(topic, args.per_topic)
        path = out_dir / f"{topic}.json"
        path.write_text(json.dumps(questions, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        total += len(questions)
        print(f"{topic:<24} {len(questions):>4}")
    print(f"{'total':<24} {total:>4}")


if __name__ == "__main__":
    main()
