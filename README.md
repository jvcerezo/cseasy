# CSEasy

An offline reviewer for the Philippine Civil Service Exam (CSE), Professional and Sub-Professional levels, for Android. Play listing: **CSEasy: Civil Service Reviewer** (`ph.cseasy.app`).

## Layout

```
app/        Flutter app (Riverpod, drift/SQLite). Ships the bank as assets/content/cse.json
content/    Source of truth: questions as JSON per section/topic, plus law texts in sources/
pipeline/   Python (stdlib only): generate, ingest, review gates, build into the app asset
docs/       Store listing, privacy policy, Data safety answers, closed-test plan, release checklist
```

## Content

| Section | How items are made | Levels |
|---|---|---|
| Numerical | Computed by `generators/numerical.py` | both |
| Analytical | Computed by `generators/analytical.py` (syllogisms via Venn enumeration, ordering via brute force) | Professional |
| Clerical | Computed by `generators/clerical.py` | Sub-Professional |
| General Information | Written from primary law texts, with verbatim quotes | both |
| Verbal | Written (English and Filipino) | both |

Sourcing rules: no actual CSC exam items (they are confidential), and nothing copied from other reviewers or apps.

### Pipeline

```sh
cd pipeline
python generate.py               # regenerate the computed sections (deterministic)
python extract_sources.py        # law pages in content/sources/raw/*.html -> plain text
python ingest.py                 # expand newly written items (key first, then shuffled)
python check_quotes.py           # gate: grounded quotes must appear verbatim in the source
python blind_solve.py export     # gate: independent solver answers without the key...
python blind_solve.py grade out/<answers>.json   # ...and only agreements become verified
python spotcheck.py              # gate: human sample sheet in out/spotcheck.md
python validate.py               # schema and duplicate checks
python build.py                  # bundle status=verified items into the app
python -m unittest discover -s tests -t .
```

`blind_solve.py api --model <model>` solves the batch through the Claude API (`pip install anthropic`, plus credentials). Using a different model from the one that wrote the items gives a more independent check. `--recheck` re-solves items flagged by an earlier blind solve, for when a solver slips.

Never edit `app/assets/content/cse.json` by hand. It is a build output.

## App

```sh
cd app
flutter test
flutter run
```

- Practice by topic or section (unseen questions first), with instant feedback and explanations.
- Spaced-repetition review queue, streaks, and per-topic accuracy.
- Timed mock exams in the CSC format, plus 50-item mini mocks, with scores by section.
- Free tier (first 10 items per topic, one full mock) and a one-time `cseasy_full_access` unlock.
- AdMob banner on results screens only, behind Google's UMP consent flow.
- "Report a problem" via prefilled email; requires `--dart-define=SUPPORT_EMAIL=...`.

Release builds read `app/android/key.properties` (gitignored) for the upload keystore and AdMob app ID. See `docs/release-checklist.md`.

## Launch constraints

- New personal Play account: a closed test with 12+ testers for 14 consecutive days is required before production. See `docs/closed-testing.md`.
- Target the March 2027 CSE: be live by mid-December 2026.
