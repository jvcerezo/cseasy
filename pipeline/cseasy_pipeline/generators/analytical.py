"""Analytical-ability generators for the CSE Professional level.

Answers are derived by brute force rather than by hand: syllogisms by
enumerating every Venn arrangement, ordering puzzles by checking every
permutation. That makes them correct by construction like the numerical set.
"""

from __future__ import annotations

import itertools
import random
import string
from typing import Callable

from .. import fmt
from ..builder import computed_question
from .numerical import NAMES

LEVELS = ("professional",)


def _q(rng: random.Random, topic: str, **kwargs) -> dict:
    return computed_question(rng, section="analytical", topic=topic, levels=LEVELS, **kwargs)


# ------------------------------------------------------------------ syllogisms

# Neutral groups, so real-world knowledge can't contradict the premises.
GROUPS = [
    "painters", "joggers", "chess players", "volunteers", "bloggers", "cyclists",
    "vegetarians", "gardeners", "singers", "bakers", "hikers", "collectors",
    "swimmers", "poets", "photographers", "early risers",
]

ALL, NO, SOME, SOME_NOT = "all", "no", "some", "some_not"

# 7 Venn regions over three sets, as membership bit-triples (outside-all is irrelevant).
REGIONS = [r for r in itertools.product((0, 1), repeat=3) if any(r)]
# A "world" is the set of non-empty regions.
WORLDS = [
    frozenset(r for r, keep in zip(REGIONS, mask) if keep)
    for mask in itertools.product((0, 1), repeat=len(REGIONS))
]


def _holds(kind: str, x: int, y: int, world: frozenset) -> bool:
    if kind == ALL:
        return not any(r[x] and not r[y] for r in world)
    if kind == NO:
        return not any(r[x] and r[y] for r in world)
    if kind == SOME:
        return any(r[x] and r[y] for r in world)
    return any(r[x] and not r[y] for r in world)


def _every_term_nonempty(world: frozenset) -> bool:
    return all(any(r[i] for r in world) for i in range(3))


def _follows(premises, conclusion, existential_import: bool) -> bool | None:
    """True/False when decidable; None if the premises are contradictory."""
    worlds = [w for w in WORLDS if not existential_import or _every_term_nonempty(w)]
    models = [w for w in worlds if all(_holds(k, x, y, w) for k, x, y in premises)]
    if not models:
        return None
    return all(_holds(*conclusion, w) for w in models)


def _sentence(kind: str, x: str, y: str) -> str:
    return {
        ALL: f"All {x} are {y}.",
        NO: f"No {x} are {y}.",
        SOME: f"Some {x} are {y}.",
        SOME_NOT: f"Some {x} are not {y}.",
    }[kind]


def _negation(kind: str, x: str, y: str) -> str:
    return {
        ALL: f"some {x} are not {y}",
        NO: f"some {x} are {y}",
        SOME: f"no {x} are {y}",
        SOME_NOT: f"all {x} are {y}",
    }[kind]


def _claim(c: tuple) -> tuple:
    kind, x, y = c
    return (kind, *sorted((x, y))) if kind in (NO, SOME) else c


def syllogism(rng: random.Random) -> dict:
    kinds = [ALL, NO, SOME, SOME_NOT]
    while True:
        names = rng.sample(GROUPS, 3)  # term 0 = A, 1 = B (middle), 2 = C
        p1 = (rng.choice(kinds), *rng.sample([0, 1], 2))
        p2 = (rng.choice(kinds), *rng.sample([1, 2], 2))
        premises = [p1, p2]
        valid, invalid = [], []
        for kind in kinds:
            for x, y in ((0, 2), (2, 0)):
                both = {_follows(premises, (kind, x, y), e) for e in (False, True)}
                # Keep only conclusions whose status doesn't depend on whether
                # "All X are Y" is read as implying that X exists.
                if both == {True}:
                    valid.append((kind, x, y))
                elif both == {False}:
                    invalid.append((kind, x, y))
        if valid and len(invalid) >= 3:
            break

    answer = rng.choice(valid)
    # "No A are C" and "No C are A" say the same thing (likewise "Some"), so
    # offering both would reveal that neither is the key.
    rng.shuffle(invalid)
    wrong, claims = [], {_claim(answer)}
    for c in invalid:
        if _claim(c) not in claims:
            wrong.append(c)
            claims.add(_claim(c))
    if len(wrong) < 3:
        return syllogism(rng)
    wrong = wrong[:3]
    text = lambda c: _sentence(c[0], names[c[1]], names[c[2]])  # noqa: E731
    premise_text = " ".join(_sentence(k, names[x], names[y]) for k, x, y in premises)
    explanation = (
        f"Both statements together force it: there is no way to arrange the groups so that "
        f"both are true and {_negation(answer[0], names[answer[1]], names[answer[2]])}. "
        + " ".join(
            f"\"{text(c)}\" does not follow: both statements can be true while "
            f"{_negation(c[0], names[c[1]], names[c[2]])}."
            for c in wrong
        )
    )
    return _q(
        rng, "syllogisms",
        stem=f"Assume both statements are true.\n{premise_text}\nWhich conclusion necessarily follows?",
        answer=text(answer),
        distractors=[text(c) for c in wrong],
        explanation=explanation,
        difficulty=3, fmt=str,
    )


# ------------------------------------------------------------- linear ordering

ORDINALS = ["first", "second", "third", "fourth", "fifth"]


def _clue_holds(clue, order: tuple[str, ...]) -> bool:
    kind, a, b = clue
    pos = {name: i for i, name in enumerate(order)}
    if kind == "ahead":
        return pos[a] < pos[b]
    if kind == "right_after":
        return pos[a] == pos[b] + 1
    if kind == "place":
        return pos[a] == b
    if kind == "one_between":
        return abs(pos[a] - pos[b]) == 2
    raise ValueError(kind)


def _clue_text(clue) -> str:
    kind, a, b = clue
    if kind == "ahead":
        return f"{a} finished ahead of {b}."
    if kind == "right_after":
        return f"{a} finished right after {b}."
    if kind == "place":
        return f"{a} finished {'last' if b == 4 else ORDINALS[b]}."
    return f"Exactly one runner finished between {a} and {b}."


def _random_true_clue(rng: random.Random, order: tuple[str, ...]):
    i, j = sorted(rng.sample(range(5), 2))
    kind = rng.choice(["ahead", "ahead", "right_after", "one_between", "place"])
    if kind == "ahead":
        return ("ahead", order[i], order[j])
    if kind == "right_after":
        i = rng.randrange(4)
        return ("right_after", order[i + 1], order[i])
    if kind == "one_between":
        i = rng.randrange(3)
        return ("one_between", *rng.sample([order[i], order[i + 2]], 2))
    # Fixing the middle place reads oddly as a lone fact; pin an end instead.
    i = rng.choice([0, 4])
    return ("place", order[i], i)


def ordering(rng: random.Random) -> dict:
    while True:
        names = rng.sample(NAMES, 5)
        order = tuple(rng.sample(names, 5))
        perms = list(itertools.permutations(names))
        clues: list = []
        while True:
            consistent = [p for p in perms if all(_clue_holds(c, p) for c in clues)]
            if len(consistent) == 1:
                break
            clue = _random_true_clue(rng, order)
            if clue not in clues:
                clues.append(clue)
        # Drop clues the puzzle doesn't need, so every clue does work.
        for clue in list(clues):
            rest = [c for c in clues if c != clue]
            if sum(all(_clue_holds(c, p) for c in rest) for p in perms) == 1:
                clues = rest
        if 3 <= len(clues) <= 6:
            break

    rng.shuffle(clues)
    # Never ask for a place a clue already states outright.
    stated = {c[2] for c in clues if c[0] == "place"}
    place = rng.choice([i for i in range(5) if i not in stated])
    answer = order[place]
    return _q(
        rng, "ordering",
        stem=(
            f"Five runners, {', '.join(names[:-1])} and {names[-1]}, finished a race with no ties.\n"
            + "\n".join(_clue_text(c) for c in clues)
            + f"\nWho finished {ORDINALS[place]}?"
        ),
        answer=answer,
        distractors=[n for n in order if n != answer],
        explanation=(
            f"Only one finishing order satisfies every clue: {', '.join(order)}. "
            f"So {answer} finished {ORDINALS[place]}."
        ),
        difficulty=3, fmt=str,
    )


# ---------------------------------------------------------- data interpretation

DATA_THEMES = [
    ("Monthly sales of four sari-sari stores (in thousand pesos)",
     ["Aling Nena", "Mang Ben", "Tindahan ni Joy", "RJ Store"], ["Jan", "Feb", "Mar", "Apr"], "sales"),
    ("Applications received by four municipal offices",
     ["Treasury", "Assessor", "Civil Registry", "Engineering"], ["Q1", "Q2", "Q3", "Q4"], "applications"),
    ("Enrollment in four barangay day-care centers",
     ["San Jose", "Sta. Cruz", "Malinis", "Bagong Silang"], ["2023", "2024", "2025", "2026"], "enrollees"),
]


def data_interpretation(rng: random.Random) -> dict:
    title, rows, cols, noun = rng.choice(DATA_THEMES)
    values = [[rng.randint(12, 95) for _ in cols] for _ in rows]
    kind = rng.choice(["max_total", "col_total", "row_average", "pct_change", "min_col"])

    if kind == "row_average":
        r = rng.randrange(len(rows))
        values[r][-1] += (-sum(values[r])) % len(cols)  # make the average whole
    if kind == "pct_change":
        r = rng.randrange(len(rows))
        p = rng.choice([10, 20, 25, 50, 75])
        # The start must make the increase a whole number, or the table and key disagree.
        values[r][0] = rng.choice([v for v in range(20, 81) if v * p % 100 == 0])
        values[r][-1] = values[r][0] * (100 + p) // 100

    row_totals = [sum(v) for v in values]
    col_totals = [sum(values[i][j] for i in range(len(rows))) for j in range(len(cols))]
    table = {
        "headers": ["", *cols],
        "rows": [[name, *map(str, v)] for name, v in zip(rows, values)],
    }

    if kind == "max_total":
        # A tie would make the question unanswerable; nudge the leader up.
        best = max(range(len(rows)), key=row_totals.__getitem__)
        if row_totals.count(row_totals[best]) > 1:
            values[best][0] += 1
            table["rows"][best][1] = str(values[best][0])
            row_totals[best] += 1
        return _q(
            rng, "data_interpretation",
            stem=f"{title}. Which had the highest total {noun} over the four periods?",
            table=table,
            answer=rows[best],
            distractors=[r for r in rows if r != rows[best]],
            explanation="Totals: " + ", ".join(f"{n} {t}" for n, t in zip(rows, row_totals))
            + f". The highest is {rows[best]}.",
            difficulty=2, fmt=str,
        )

    if kind == "min_col":
        worst = min(range(len(cols)), key=col_totals.__getitem__)
        if col_totals.count(col_totals[worst]) > 1:
            values[0][worst] -= 1
            table["rows"][0][worst + 1] = str(values[0][worst])
            col_totals[worst] -= 1
        return _q(
            rng, "data_interpretation",
            stem=f"{title}. In which period were the combined {noun} lowest?",
            table=table,
            answer=cols[worst],
            distractors=[c for c in cols if c != cols[worst]],
            explanation="Combined: " + ", ".join(f"{c} {t}" for c, t in zip(cols, col_totals))
            + f". The lowest is {cols[worst]}.",
            difficulty=2, fmt=str,
        )

    if kind == "col_total":
        j = rng.randrange(len(cols))
        ans = col_totals[j]
        return _q(
            rng, "data_interpretation",
            stem=f"{title}. What were the combined {noun} of all four in {cols[j]}?",
            table=table,
            answer=ans,
            distractors=[col_totals[(j + 1) % len(cols)], ans + 10, ans - values[0][j]],
            explanation=" + ".join(str(values[i][j]) for i in range(len(rows))) + f" = {ans}.",
            difficulty=1, fmt=fmt.num,
        )

    if kind == "row_average":
        row_totals = [sum(v) for v in values]
        ans = row_totals[r] // len(cols)
        return _q(
            rng, "data_interpretation",
            stem=f"{title}. What is the average per period for {rows[r]}?",
            table=table,
            answer=ans,
            distractors=[row_totals[r] / 3, max(values[r]), ans + 3],
            explanation=f"({' + '.join(map(str, values[r]))}) ÷ {len(cols)} = {row_totals[r]} ÷ {len(cols)} = {ans}.",
            difficulty=2, fmt=fmt.num,
        )

    first, last = values[r][0], values[r][-1]
    return _q(
        rng, "data_interpretation",
        stem=f"{title}. By what percent did {rows[r]}'s {noun} increase from {cols[0]} to {cols[-1]}?",
        table=table,
        answer=p,
        distractors=[(last - first) * 100 / last, last - first, p + 5],
        explanation=f"Increase = {last} − {first} = {last - first}. {last - first} ÷ {first} = {p / 100:g}, so {p}%.",
        difficulty=3, fmt=fmt.pct, filler_step=5,
    )


# --------------------------------------------------------------- coding/decoding

CODE_WORDS = [
    "CLERK", "MEMO", "FILE", "OFFICE", "AGENCY", "BUDGET", "PERMIT", "LEDGER", "RECORD",
    "NOTICE", "REPORT", "SALARY", "VOUCHER", "STAMP", "FOLDER", "DESK", "LOBBY", "PANEL",
]


def _shift(word: str, k: int) -> str:
    return "".join(chr((ord(c) - 65 + k) % 26 + 65) for c in word)


def _atbash(word: str) -> str:
    return "".join(chr(155 - ord(c)) for c in word)


def coding(rng: random.Random) -> dict:
    sample, target = rng.sample(CODE_WORDS, 2)
    rule = rng.choice(["shift", "shift", "atbash", "reverse_shift"])
    k = rng.choice([1, 2, 3, -1, -2])

    rules: dict[str, Callable[[str], str]] = {
        "shift": lambda w: _shift(w, k),
        "atbash": _atbash,
        "reverse_shift": lambda w: _shift(w[::-1], k),
    }
    encode = rules[rule]
    ans = encode(target)
    distractors = [
        _shift(target, -k), _shift(target, k + 1), ans[::-1],
        _shift(target[::-1], k) if rule == "shift" else _shift(target, k),
        _shift(target, k - 1 if k - 1 else 2), _atbash(target), target[::-1],
    ]
    how = {
        "shift": f"each letter moves {abs(k)} place{'s' if abs(k) > 1 else ''} {'forward' if k > 0 else 'back'} in the alphabet",
        "atbash": "each letter is replaced by its mirror in the alphabet (A↔Z, B↔Y, C↔X, …)",
        "reverse_shift": f"the word is reversed, then each letter moves {abs(k)} place{'s' if abs(k) > 1 else ''} {'forward' if k > 0 else 'back'}",
    }[rule]
    return _q(
        rng, "coding_decoding",
        stem=f"In a certain code, {sample} is written as {encode(sample)}. How is {target} written in that code?",
        answer=ans,
        distractors=distractors,
        explanation=f"In the example, {how}. Applying the same rule, {target} becomes {ans}.",
        difficulty=2, fmt=str,
    )


# ---------------------------------------------------------------- letter series

L = string.ascii_uppercase


def letter_series(rng: random.Random) -> dict:
    kind = rng.choice(["step", "growing", "pairs", "alternating"])

    if kind == "step":
        step = rng.randint(2, 4)
        start = rng.randint(0, 25 - 5 * step)
        idx = [start + i * step for i in range(6)]
        shown, ans = [L[i] for i in idx[:5]], L[idx[5]]
        explanation = f"Each letter skips ahead {step} places: {L[idx[4]]} + {step} = {ans}."
        distractors = [L[idx[5] - 1], L[min(idx[5] + 1, 25)], L[idx[4] + step - 2]]
    elif kind == "growing":
        start = rng.randint(0, 6)
        idx = [start]
        for gap in range(1, 6):
            idx.append(idx[-1] + gap)
        shown, ans = [L[i] for i in idx[:5]], L[idx[5]]
        explanation = f"The gaps grow by one each time (+1, +2, +3, +4, +5): {L[idx[4]]} + 5 = {ans}."
        distractors = [L[idx[4] + 4], L[idx[4] + 6], L[idx[4] + 3]]
    elif kind == "pairs":
        start = rng.randint(0, 8)
        pairs = [L[start + i] + L[25 - start - i] for i in range(5)]
        shown, ans = pairs[:4], pairs[4]
        explanation = (
            "The first letters go forward (" + ", ".join(p[0] for p in pairs[:4])
            + ") while the second letters go backward one letter at a time ("
            + ", ".join(p[1] for p in pairs[:4]) + f"). Next is {ans}."
        )
        distractors = [ans[0] + L[25 - start - 3], L[start + 5] + ans[1], ans[::-1]]
    else:
        a, b = rng.randint(0, 6), rng.randint(14, 20)
        da, db = rng.randint(1, 3), -rng.randint(1, 3)
        seq = []
        for i in range(4):
            seq += [L[a + i * da], L[b + i * db]]
        shown, ans = seq[:7], seq[7]
        explanation = (
            f"Two series alternate: {', '.join(seq[0::2][:4])} (step {da:+d}) and "
            f"{', '.join(seq[1::2][:3])} (step {db:+d}). The next letter continues the second: {ans}."
        )
        distractors = [L[a + 4 * da], L[b + 3 * db - db + 1], L[b + 3 * db - 1]]

    distractors += [L[(L.index(ans[-1]) + d) % 26] for d in (1, -1, 2, -2)]
    return _q(
        rng, "letter_series",
        stem=f"What comes next in the series?\n{', '.join(shown)}, ___",
        answer=ans,
        distractors=distractors,
        explanation=explanation,
        difficulty=2, fmt=str,
    )


# --------------------------------------------------------------- symbolic logic

# Each clause is (statement, its negation). Unrelated clauses are paired at
# random, so everyday knowledge can't stand in for the logical form.
CLAUSES = [
    ("the office opens early", "the office does not open early"),
    ("Ana passes the exam", "Ana does not pass the exam"),
    ("the budget is approved", "the budget is not approved"),
    ("the road is flooded", "the road is not flooded"),
    ("the printer has ink", "the printer has no ink"),
    ("the store gives a discount", "the store does not give a discount"),
    ("Ben attends the seminar", "Ben does not attend the seminar"),
    ("the project is finished", "the project is not finished"),
    ("the alarm rings", "the alarm does not ring"),
    ("the clerk signs the form", "the clerk does not sign the form"),
    ("the bus is late", "the bus is not late"),
    ("the plants are watered", "the plants are not watered"),
    ("the team wins", "the team does not win"),
    ("the library is open", "the library is not open"),
    ("Carla gets a promotion", "Carla does not get a promotion"),
    ("the shipment arrives", "the shipment does not arrive"),
]

NONE_FOLLOWS = "None of these necessarily follows."

# A formula is a function from an assignment (tuple of bools) to bool.
Formula = Callable[[tuple[bool, ...]], bool]


def _entails(premises: list[Formula], conclusion: Formula, n: int) -> bool:
    """True when every assignment that satisfies the premises satisfies the conclusion."""
    return all(
        conclusion(v)
        for v in itertools.product((False, True), repeat=n)
        if all(p(v) for p in premises)
    )


def _equivalent(a: Formula, b: Formula, n: int) -> bool:
    return all(a(v) == b(v) for v in itertools.product((False, True), repeat=n))


def _cap(text: str) -> str:
    return text[0].upper() + text[1:] + "."


def _lit(i: int, positive: bool) -> tuple[Formula, Callable[[list], str]]:
    """Literal for variable i, with a renderer that takes the clause list."""
    return (lambda v: v[i]) if positive else (lambda v: not v[i]), lambda c: c[i][0 if positive else 1]


def symbolic_logic(rng: random.Random) -> dict:
    form = rng.choice(["ponens", "tollens", "affirm", "deny", "chain", "chain_tollens", "either", "contrapositive"])
    clauses = rng.sample(CLAUSES, 3)
    imp = lambda a, b: (lambda v: (not a(v)) or b(v))  # noqa: E731
    P, nP = _lit(0, True), _lit(0, False)
    Q, nQ = _lit(1, True), _lit(1, False)
    R, nR = _lit(2, True), _lit(2, False)
    if_ = lambda a, b: f"If {a[1](clauses)}, then {b[1](clauses)}."  # noqa: E731

    if form == "contrapositive":
        stem = f"Which statement means the same as the following?\n\"{if_(P, Q)}\""
        options = {
            if_(nQ, nP): imp(nQ[0], nP[0]),
            if_(Q, P): imp(Q[0], P[0]),
            if_(nP, nQ): imp(nP[0], nQ[0]),
            if_(P, nQ): imp(P[0], nQ[0]),
        }
        original = imp(P[0], Q[0])
        good = [text for text, f in options.items() if _equivalent(f, original, 3)]
        assert len(good) == 1
        answer = good[0]
        return _q(
            rng, "symbolic_logic",
            stem=stem,
            answer=answer,
            distractors=[t for t in options if t != answer],
            explanation=(
                "\"If P, then Q\" is equivalent only to its contrapositive, \"If not Q, then not P.\" "
                "Reversing it (\"If Q, then P\") or negating both parts (\"If not P, then not Q\") "
                f"changes the meaning. Answer: {answer}"
            ),
            difficulty=3, fmt=str,
        )

    premises_text, premises, candidates, rule = {
        "ponens": lambda: ([if_(P, Q), _cap(P[1](clauses))], [imp(P[0], Q[0]), P[0]], [Q, nQ, nP],
                           "The condition is met, so the result must follow."),
        "tollens": lambda: ([if_(P, Q), _cap(nQ[1](clauses))], [imp(P[0], Q[0]), nQ[0]], [nP, P, Q],
                            "The result did not happen, so the condition could not have been met."),
        "affirm": lambda: ([if_(P, Q), _cap(Q[1](clauses))], [imp(P[0], Q[0]), Q[0]], [P, nP, nQ],
                           "Knowing the result happened says nothing about the condition: the result may have other causes."),
        "deny": lambda: ([if_(P, Q), _cap(nP[1](clauses))], [imp(P[0], Q[0]), nP[0]], [Q, nQ, P],
                         "The rule only says what happens when the condition is met; when it is not met, the result may or may not happen."),
        "chain": lambda: ([if_(P, Q), if_(Q, R), _cap(P[1](clauses))], [imp(P[0], Q[0]), imp(Q[0], R[0]), P[0]], [R, nR, nQ],
                          "The first rule gives the middle step, and the second rule carries it to the end."),
        "chain_tollens": lambda: ([if_(P, Q), if_(Q, R), _cap(nR[1](clauses))], [imp(P[0], Q[0]), imp(Q[0], R[0]), nR[0]], [nP, P, Q],
                                  "The last result did not happen, so working backward neither earlier condition could have been met."),
        "either": lambda: ([f"Either {P[1](clauses)} or {Q[1](clauses)} (or both).", _cap(nP[1](clauses))],
                           [lambda v: v[0] or v[1], nP[0]], [Q, nQ, P],
                           "At least one of the two must be true, and the first is ruled out, so the second must hold."),
    }[form]()

    entailed = [c for c in candidates if _entails(premises, c[0], 3)]
    assert len(entailed) <= 1
    answer = _cap(entailed[0][1](clauses)) if entailed else NONE_FOLLOWS
    choices = [_cap(c[1](clauses)) for c in candidates] + [NONE_FOLLOWS]
    return _q(
        rng, "symbolic_logic",
        stem="Assume these statements are true:\n" + "\n".join(premises_text) + "\nWhich of the following must also be true?",
        answer=answer,
        distractors=[c for c in choices if c != answer],
        explanation=f"{rule} Answer: {answer}",
        difficulty=3 if form in ("affirm", "deny", "chain_tollens") else 2, fmt=str,
    )


GENERATORS: dict[str, Callable[[random.Random], dict]] = {
    "syllogisms": syllogism,
    "ordering": ordering,
    "data_interpretation": data_interpretation,
    "coding_decoding": coding,
    "letter_series": letter_series,
    "symbolic_logic": symbolic_logic,
}
