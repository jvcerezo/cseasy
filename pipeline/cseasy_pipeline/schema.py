"""Question schema shared by every generator, the validator and the build step.

The JSON files under content/ are the source of truth. Anything that does not
pass `validate_question` never reaches the app.
"""

from __future__ import annotations

EXAMS = {"cse"}
LEVELS = {"professional", "subprofessional"}
SECTIONS = {"verbal", "numerical", "analytical", "general_info", "clerical"}

# computed      answer derived by code; correct by construction
# llm-grounded  written by a model from a supplied source passage, must cite it
# llm           written by a model without a source passage (verbal items)
METHODS = {"computed", "llm-grounded", "llm"}

# draft     not yet through the review gates
# flagged   failed a gate; needs a fix or rejection
# verified  passed every gate; ships in the app
# rejected  kept for history so the same item is not regenerated
STATUSES = {"draft", "flagged", "verified", "rejected"}

CHOICE_COUNT = 4

REQUIRED_FIELDS = {
    "id": str,
    "exam": str,
    "levels": list,
    "section": str,
    "topic": str,
    "stem": str,
    "choices": list,
    "answer": int,
    "explanation": str,
    "method": str,
    "status": str,
    "difficulty": int,
}


def validate_question(q: dict) -> list[str]:
    """Return a list of problems with `q`; an empty list means it is valid."""
    errors: list[str] = []
    qid = q.get("id", "<no id>")

    for field, kind in REQUIRED_FIELDS.items():
        if field not in q:
            errors.append(f"{qid}: missing field '{field}'")
        elif not isinstance(q[field], kind) or (kind is int and isinstance(q[field], bool)):
            errors.append(f"{qid}: '{field}' must be {kind.__name__}")
    if errors:
        return errors

    if q["exam"] not in EXAMS:
        errors.append(f"{qid}: unknown exam '{q['exam']}'")
    if not q["levels"] or not set(q["levels"]) <= LEVELS:
        errors.append(f"{qid}: levels must be a non-empty subset of {sorted(LEVELS)}")
    if q["section"] not in SECTIONS:
        errors.append(f"{qid}: unknown section '{q['section']}'")
    if q["method"] not in METHODS:
        errors.append(f"{qid}: unknown method '{q['method']}'")
    if q["status"] not in STATUSES:
        errors.append(f"{qid}: unknown status '{q['status']}'")
    if q["difficulty"] not in (1, 2, 3):
        errors.append(f"{qid}: difficulty must be 1, 2 or 3")
    if not q["stem"].strip():
        errors.append(f"{qid}: empty stem")
    if not q["explanation"].strip():
        errors.append(f"{qid}: empty explanation")

    choices = q["choices"]
    if len(choices) != CHOICE_COUNT:
        errors.append(f"{qid}: needs exactly {CHOICE_COUNT} choices, has {len(choices)}")
    elif any(not isinstance(c, str) or not c.strip() for c in choices):
        errors.append(f"{qid}: every choice must be a non-empty string")
    elif len({c.strip().lower() for c in choices}) != len(choices):
        errors.append(f"{qid}: duplicate choices {choices}")
    if not 0 <= q["answer"] < len(choices):
        errors.append(f"{qid}: answer index {q['answer']} out of range")

    table = q.get("table")
    if table is not None:
        errors += _validate_table(qid, table)

    # Grounded items must say where the answer comes from; the quote matcher
    # checks the citation against the source text in a later gate.
    if q["method"] == "llm-grounded":
        for field in ("source", "source_doc", "quote"):
            if not isinstance(q.get(field), str) or not q[field].strip():
                errors.append(f"{qid}: llm-grounded items need '{field}'")

    return errors


def _validate_table(qid: str, table: object) -> list[str]:
    """Optional data table shown under the stem: {"headers": [...], "rows": [[...]]}."""
    if not isinstance(table, dict):
        return [f"{qid}: table must be an object"]
    headers, rows = table.get("headers"), table.get("rows")
    if not isinstance(headers, list) or not headers or not all(isinstance(h, str) for h in headers):
        return [f"{qid}: table.headers must be a non-empty list of strings"]
    if not isinstance(rows, list) or not rows:
        return [f"{qid}: table.rows must be a non-empty list"]
    for row in rows:
        if not isinstance(row, list) or len(row) != len(headers) or not all(isinstance(c, str) for c in row):
            return [f"{qid}: every table row needs {len(headers)} string cells"]
    return []
