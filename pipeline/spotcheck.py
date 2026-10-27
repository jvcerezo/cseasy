"""Gate 4: a human spot-check sheet for written (model-authored) items.

    python pipeline/spotcheck.py [--count 20] [--seed N]

Writes pipeline/out/spotcheck.md with a random sample of verified written
items, weighted toward Verbal (no source text backs those up). Mark each
item OK or describe the problem; any problem found is reason to flag the
item and look harder at its batch.
"""

from __future__ import annotations

import argparse
import json
import random

from cseasy_pipeline.paths import CONTENT
from blind_solve import OUT


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--count", type=int, default=20)
    parser.add_argument("--seed", type=int, default=None)
    args = parser.parse_args()

    written = [
        q
        for path in sorted((CONTENT / "cse").rglob("*.json"))
        for q in json.loads(path.read_text(encoding="utf-8"))
        if q.get("method") in ("llm", "llm-grounded") and q.get("status") == "verified"
    ]
    rng = random.Random(args.seed)
    verbal = [q for q in written if q["section"] == "verbal"]
    grounded = [q for q in written if q["section"] != "verbal"]
    n_verbal = min(len(verbal), round(args.count * 0.6))
    sample = rng.sample(verbal, n_verbal) + rng.sample(grounded, min(len(grounded), args.count - n_verbal))

    lines = ["# CSEasy spot check", "", "Mark each item **OK** or write what's wrong.", ""]
    for i, q in enumerate(sample, 1):
        lines += [f"## {i}. `{q['id']}`", "", q["stem"], ""]
        for j, choice in enumerate(q["choices"]):
            mark = " ✅" if j == q["answer"] else ""
            lines.append(f"- {'ABCD'[j]}. {choice}{mark}")
        lines += ["", f"*Explanation:* {q['explanation']}"]
        if q.get("source"):
            lines.append(f"*Source:* {q['source']}")
        lines += ["", "Verdict: ______", ""]

    OUT.mkdir(exist_ok=True)
    path = OUT / "spotcheck.md"
    path.write_text("\n".join(lines), encoding="utf-8")
    print(f"{len(sample)} items -> {path}")


if __name__ == "__main__":
    main()
