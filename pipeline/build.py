"""Bundle verified questions into the app asset.

    python pipeline/build.py

Only `status: verified` items ship. Review-only fields stay in content/.
"""

from __future__ import annotations

import hashlib
import json
import sys
from collections import Counter

from cseasy_pipeline.paths import APP_ASSET
from validate import load_all, problems

SHIPPED_FIELDS = (
    "id", "levels", "section", "topic", "stem",
    "choices", "answer", "explanation", "source", "difficulty",
)


def main() -> None:
    questions = load_all()
    errors = problems(questions)
    if errors:
        print("\n".join(errors))
        sys.exit("validation failed; nothing built")

    shipped = [
        {k: q.get(k) for k in SHIPPED_FIELDS}
        for q in sorted(questions, key=lambda q: q["id"])
        if q["status"] == "verified"
    ]
    body = json.dumps(shipped, ensure_ascii=False, separators=(",", ":"))
    # Content hash as the version: changes exactly when shipped content does.
    version = hashlib.sha256(body.encode()).hexdigest()[:12]

    APP_ASSET.parent.mkdir(parents=True, exist_ok=True)
    APP_ASSET.write_text(f'{{"version":"{version}","questions":{body}}}', encoding="utf-8")

    sections = Counter(q["section"] for q in shipped)
    print(f"wrote {len(shipped)} questions ({dict(sections)}) version {version}")
    print(f"-> {APP_ASSET}")


if __name__ == "__main__":
    main()
