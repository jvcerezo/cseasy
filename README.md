# CSEasy

Offline Civil Service Exam (CSE) reviewer for Android. Play Store listing: **CSEasy: Civil Service Reviewer 2027** (`ph.cseasy.app`).

## Layout

```
app/        Flutter app (Riverpod). Ships the question bank as assets/content/cse.json
content/    Source of truth: questions as JSON, one file per topic
pipeline/   Python (stdlib only): generate -> validate -> build into the app asset
```

## Content workflow

```sh
cd pipeline
python generate_numerical.py      # regenerate computed numerical items
python validate.py                # schema + duplicate checks; non-zero exit on problems
python build.py                   # bundle status=verified items into app/assets/content/cse.json
python -m unittest discover -s tests -t .
```

Never edit `app/assets/content/cse.json` by hand; it is a build output.

### Question sourcing rules

- No real past CSC exam items (they are confidential) and nothing copied from other reviewers or apps.
- `computed`: the answer is derived by code (numerical, most analytical). Correct by construction.
- `llm-grounded`: drafted from a supplied source passage (Constitution, RA 6713, ...) and must cite it.
- `llm`: verbal items with no source passage. These always get human spot checks.

### Review gates (before `status: verified`)

1. Computed items: generator tests re-derive answers from the stem text.
2. Grounded items: a quote matcher confirms the cited text exists in the source.
3. Blind solve: a second model answers without the key; any disagreement or ambiguity means `flagged`.
4. Human spot check: a random sample per batch, with Verbal weighted heavily.
5. After launch: the in-app report button and per-question miss-rate outliers.

## App

```sh
cd app
flutter test
flutter run
```

## Launch constraints

- New personal Play account: a closed test with 12+ testers for 14 consecutive days is required before production access. Start it as soon as the core loop is usable.
- Target the March 2027 CSE: be live by mid-December 2026 so the listing ranks before the search spike.
