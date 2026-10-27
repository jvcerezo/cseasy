"""Gate 3: an independent solver answers every draft item without seeing the key.

    python pipeline/blind_solve.py export            # writes pipeline/out/blind_batch.json
    python pipeline/blind_solve.py api [--model M]   # solves the batch via the Claude API
    python pipeline/blind_solve.py grade ANSWERS     # applies a solver's answers

The batch contains only id, stem, table and choices: no key, explanation,
source or quote. Any solver can fill it (the API mode below, a different
model, or a person), as long as it writes
    {"<id>": {"choice": <index>, "confident": true|false, "note": "..."}}

Grading: a draft becomes `verified` only when the solver picks the key,
says it is confident (exactly one defensible answer), and, for grounded
items, the quote check passes. Everything else becomes `flagged` with the
reason recorded, for a fix or rejection.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from check_quotes import check as check_quote
from cseasy_pipeline.paths import CONTENT

OUT = Path(__file__).resolve().parent / "out"
BATCH = OUT / "blind_batch.json"

SOLVER_INSTRUCTIONS = (
    "You are checking practice questions for the Philippine Civil Service Exam. "
    "Answer the question on your own. Pick the index (0-based) of the single best choice. "
    "Set confident to false if no choice is correct, more than one choice is defensible, "
    "or the question is ambiguous or badly worded, and say why in note. "
    'Reply with JSON only: {"choice": <int>, "confident": <bool>, "note": "<string>"}'
)


def _gradable(q: dict, recheck: bool) -> bool:
    """Drafts, plus (with --recheck) items flagged only by an earlier blind solve."""
    if q.get("status") == "draft":
        return True
    return recheck and q.get("status") == "flagged" and q.get("flag_reason", "").startswith("blind solve")


def candidates(recheck: bool) -> list[tuple[Path, dict]]:
    found = []
    for path in sorted((CONTENT / "cse").rglob("*.json")):
        for q in json.loads(path.read_text(encoding="utf-8")):
            if _gradable(q, recheck):
                found.append((path, q))
    return found


def export(recheck: bool) -> None:
    batch = []
    for _, q in candidates(recheck):
        item = {"id": q["id"], "stem": q["stem"], "choices": q["choices"]}
        if "table" in q:
            item["table"] = q["table"]
        batch.append(item)
    OUT.mkdir(exist_ok=True)
    BATCH.write_text(json.dumps(batch, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"exported {len(batch)} items -> {BATCH}")


def solve_with_api(model: str) -> None:
    import anthropic  # optional dependency: pip install anthropic

    client = anthropic.Anthropic()
    batch = json.loads(BATCH.read_text(encoding="utf-8"))
    answers: dict[str, dict] = {}
    for item in batch:
        prompt = json.dumps({k: v for k, v in item.items() if k != "id"}, ensure_ascii=False)
        response = client.beta.messages.create(
            model=model,
            max_tokens=2000,
            output_config={"effort": "medium"},
            betas=["server-side-fallback-2026-07-01"],
            fallbacks="default",
            system=SOLVER_INSTRUCTIONS,
            messages=[{"role": "user", "content": prompt}],
        )
        if response.stop_reason == "refusal":
            answers[item["id"]] = {"choice": -1, "confident": False, "note": "solver refused"}
            continue
        text = next((b.text for b in response.content if b.type == "text"), "")
        try:
            answers[item["id"]] = json.loads(text[text.index("{"): text.rindex("}") + 1])
        except ValueError:
            answers[item["id"]] = {"choice": -1, "confident": False, "note": f"unparseable: {text[:200]}"}
        print(f"{item['id']}: {answers[item['id']]}")
    path = OUT / f"blind_answers_{model}.json"
    path.write_text(json.dumps(answers, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"wrote {path}; now run: python pipeline/blind_solve.py grade {path}")


def grade(answers_path: Path, recheck: bool) -> None:
    answers = json.loads(answers_path.read_text(encoding="utf-8"))
    by_file: dict[Path, list[dict]] = {}
    verified = flagged = missing = 0

    for path in sorted((CONTENT / "cse").rglob("*.json")):
        by_file[path] = json.loads(path.read_text(encoding="utf-8"))

    for path, items in by_file.items():
        for q in items:
            if not _gradable(q, recheck):
                continue
            answer = answers.get(q["id"])
            if answer is None:
                if q.get("status") == "draft":
                    missing += 1
                continue
            reasons = []
            if answer.get("choice") != q["answer"]:
                picked = answer.get("choice")
                label = q["choices"][picked] if isinstance(picked, int) and 0 <= picked < len(q["choices"]) else picked
                reasons.append(f"solver picked {label!r}, key is {q['choices'][q['answer']]!r}")
            if not answer.get("confident", False):
                reasons.append("solver not confident")
            if q.get("method") == "llm-grounded" and (quote_problem := check_quote(q)):
                reasons.append(f"quote check: {quote_problem}")
            if answer.get("note") and reasons:
                reasons.append(f"note: {answer['note']}")

            if reasons:
                q["status"] = "flagged"
                q["flag_reason"] = "blind solve: " + "; ".join(reasons)
                flagged += 1
                print(f"FLAGGED {q['id']}: {q['flag_reason']}")
            else:
                q["status"] = "verified"
                q.pop("flag_reason", None)
                verified += 1
        path.write_text(json.dumps(items, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    print(f"verified {verified}, flagged {flagged}, no answer {missing}")
    if missing:
        sys.exit(1)


def main() -> None:
    parser = argparse.ArgumentParser()
    sub = parser.add_subparsers(dest="cmd", required=True)
    exp = sub.add_parser("export")
    # Re-solve items an earlier solver flagged, e.g. after a solver slip.
    exp.add_argument("--recheck", action="store_true")
    api = sub.add_parser("api")
    # A different model from the one that wrote the items gives a more
    # independent check, e.g. --model claude-sonnet-5-5.
    api.add_argument("--model", default="claude-opus-5-5")
    g = sub.add_parser("grade")
    g.add_argument("answers", type=Path)
    g.add_argument("--recheck", action="store_true")
    args = parser.parse_args()

    if args.cmd == "export":
        export(args.recheck)
    elif args.cmd == "api":
        solve_with_api(args.model)
    else:
        grade(args.answers, args.recheck)


if __name__ == "__main__":
    main()
