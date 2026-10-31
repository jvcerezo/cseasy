# CSE exam research (2026-10-27)

What the real Career Service Exam (CSE-PPT) covers, compared with the CSEasy bank.

## Method and limits

- Reddit blocks automated access, and searches turned up no Reddit threads, so this
  has no first-person Reddit accounts. CSC's own site (csc.gov.ph) also returned 403.
- Sources are secondary pages that quote CSC Examination Announcement No. 03, s. 2026
  and Examination Advisory No. 10, s. 2026. Confirm against the CSC PDFs before release.
- Actual exam items are confidential, and RA 9416 penalizes leaking them. Match the
  question *types* only; never reproduce "recalled" live items.

## Official scope

| Subtest | Level | Sub-topics |
|---|---|---|
| Verbal (English **and Filipino**) | both | word meaning, sentence completion, error recognition, sentence structure, paragraph organization, reading comprehension |
| Numerical | both | basic operations, number sequence, word problems |
| Analytical | Professional | word analogy, symbolic logic / abstract reasoning, identifying assumptions and drawing conclusions, data interpretation |
| Clerical | Sub-Professional | filing, spelling |
| General Information | both | Constitution, RA 6713, peace and human rights, environment management and protection |

## Format

- Professional: 170 items = **150 scored + 20 EDQ** (an unscored personal-data
  questionnaire), 3h10m.
- Sub-Professional: 165 items = **145 scored + 20 EDQ**, 2h40m.
- Passing: general rating of at least 80.00 (weighted, so one subtest can be below 80).
- CSC publishes no per-subtest item counts or weights.
- No calculators, so numbers should be mental-math friendly.
- Passing rate: about 14.6% (March 2025) and 15.1% (August 2025). Prep sites call
  Analytical the hardest Professional subtest.

## Gaps in the CSEasy bank (as found; all addressed 2026-10-27, see below)

| Area | Have | Gap |
|---|---|---|
| Verbal | 116, English-heavy | Biggest subtest but our smallest. Missing paragraph organization, sentence completion and error recognition formats. Filipino is only 20 vocabulary items (no grammar, sawikain or reading). Reading comprehension is only 11. |
| Analytical | 240: calendar, coding, letter series, ordering, syllogisms, data interpretation | Missing identifying assumptions / drawing conclusions. Word analogy sits in Verbal, not Analytical. Calendar, coding and letter series are outside the published scope. |
| Clerical | 80: exact match, filing | **Spelling is missing.** Exact-match isn't in the published scope. |
| Numerical | 400 | Matches scope. Check that numbers suit mental math. |
| General Info | 161 | Matches scope. Human rights (24) and environment (25) are thin next to the Constitution (77). |
| Mock format | 170 / 165 scored items | Should be 150 / 145 scored in the same time. |

## Sources

- https://open-exam-prep.com/blog/philippine-civil-service-professional-exam-guide-2026
- https://open-exam-prep.com/blog/cse-subprofessional-2026-official-coverage-review-plan
- https://www.thesummitexpress.com/2025/10/august-2026-civil-service-exam-cse-ppt-application-schedule-requirements.html
- https://pia.gov.ph/news/civil-service-eligibility-key-to-government-entry-csc/
- https://csc.gov.ph/csc-welcomes-new-eligibles-as-46k-pass-the-civil-service-exams
- https://civpasser.com/blog/cse-verbal-ability
- https://www.examreviewph.com/2024/06/balarilang-filipino-at-talasalitaan-verbal-ability-filipino-reviewer-csc.html
- https://mccid.edu.ph/cscreview/datainterpretation.html

## Changes made (2026-10-27)

- Mock exams are now 150 / 145 scored items, in the same time limits.
- Verbal: added paragraph organization (20), sentence completion (25), error recognition
  with a "No error" option (25), 20 more reading comprehension items, Filipino wastong
  gamit (19 shipped), sawikain (25) and Filipino reading (10).
- Analytical: added assumptions and conclusions (30) and a computed symbolic-logic
  generator (40, keys checked by truth table). Word analogy moved here from Verbal
  (Professional only) and grew to 30. Calendar problems were removed.
- Clerical: added a spelling generator (60, from a curated list of words and their
  misspellings that excludes words with accepted variant spellings). Filing went up to 60,
  and exact-match was removed.
- Rejected during blind solve: Filipino word-pair items (pinto/pintuan, operahan/operahin,
  walisan/walisin, punasan/punasin, pahiran/pahirin), where common usage differs from the
  KWF rule, and a "Neither ... were" error item. Both answers are defensible in each case.


## Changes made (2026-10-31)

- General Information: human rights 24 -> 51 (more UDHR articles, the rest of the Bill of
  Rights, the Commission on Human Rights), environment 25 -> 45 (RA 9003, 8749, 9275, 9729),
  RA 6713 35 -> 45. Every item quotes its source verbatim and passed two independent
  blind solves (Sonnet, then Opus).
- Clerical (Sub-Professional): filing and spelling 60 -> 90 each. The filing generator
  depended on Python's hash seed (it listed a set unsorted); it is now deterministic, with a
  test, so the filing set was regenerated before launch. The new items passed a blind solve
  (one solver slip on a filing item, key rechecked by hand).
- Still in scope only: no ARTA, history or geography items, since the CSC coverage above
  doesn't list them.

## Full content audit (2026-10-31)

All 1,342 shipped items were re-checked. Every filing key was re-sorted by a script; the
other 1,252 items were blind-solved by Opus (answers written before seeing keys), then
reviewed with keys, explanations and source texts. No blind answer disagreed with a key.
Fixes: grammar items whose (A)-(D) labels didn't match the choice order now use brackets;
one Constitution distractor that was arguably true was replaced; Filipino and assumptions
explanations clarified; generator fixes (age and fraction explanation steps, a "0%"
distractor, unrealistic pipe times and speeds, duplicates that differed only in names,
symbolic-logic stem punctuation). The 124 regenerated items were audited again the same way.
