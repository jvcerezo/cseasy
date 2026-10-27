"""Clerical-ability generators for the CSE Subprofessional level.

Clerical items test speed and accuracy with records: spotting tiny copy
errors and putting names in filing order. Both are fully computable.
"""

from __future__ import annotations

import random
from typing import Callable

from ..builder import computed_question

LEVELS = ("subprofessional",)

GIVEN = [
    "Maria", "Jose", "Ana", "Juan", "Cristina", "Mark", "Liza", "Paolo", "Rhea", "Carlo",
    "Grace", "Ramon", "Elena", "Rodel", "Joy", "Vincent", "Teresa", "Miguel", "Andrea", "Noel",
]
# Single-word surnames only: multi-word ones (Dela Cruz, De Leon) follow
# agency-specific filing rules we can't assume.
SURNAMES = [
    "Santos", "Reyes", "Cruz", "Bautista", "Ocampo", "Garcia", "Mendoza", "Torres", "Castillo",
    "Flores", "Villanueva", "Ramos", "Navarro", "Aquino", "Salazar", "Mercado", "Aguilar",
    "Rivera", "Gonzales", "Lopez", "Pascual", "Domingo", "Soriano", "Valdez", "Manalo", "Cabrera",
]
STREETS = ["Rizal", "Mabini", "Bonifacio", "Luna", "Burgos", "Del Pilar", "Quezon", "Magsaysay"]
TOWNS = ["Quezon City", "Pasig City", "Tarlac City", "Malolos", "Calamba", "Iloilo City", "Tagum City"]

CONFUSABLE = {"O": "0", "0": "O", "l": "1", "1": "l", "S": "5", "5": "S", "B": "8", "8": "B",
              "e": "c", "c": "e", "n": "m", "m": "n", "u": "v", "v": "u", "a": "o", "o": "a"}


def _q(rng: random.Random, topic: str, **kwargs) -> dict:
    return computed_question(rng, section="clerical", topic=topic, levels=LEVELS, fmt=str, **kwargs)


def _record(rng: random.Random) -> str:
    kind = rng.choice(["name", "address", "tin", "reference"])
    if kind == "name":
        return f"{rng.choice(GIVEN)} {rng.choice('ABCDEFGHJLMNPRSTV')}. {rng.choice(SURNAMES)}"
    if kind == "address":
        return f"{rng.randint(1, 999)} {rng.choice(STREETS)} St., Brgy. {rng.randint(1, 200)}, {rng.choice(TOWNS)}"
    if kind == "tin":
        return "-".join(f"{rng.randint(0, 999):03d}" for _ in range(3)) + "-000"
    return f"OR-{rng.randint(2020, 2027)}-{rng.randint(0, 99999):05d}"


def _mutate(rng: random.Random, text: str) -> str:
    """One small copy error of the kind clerical items test for."""
    while True:
        chars = list(text)
        i = rng.randrange(len(chars))
        kind = rng.choice(["swap", "confuse", "digit", "drop"])
        if kind == "swap" and i < len(chars) - 1 and chars[i] != chars[i + 1] and chars[i].isalnum() and chars[i + 1].isalnum():
            chars[i], chars[i + 1] = chars[i + 1], chars[i]
        elif kind == "confuse" and chars[i] in CONFUSABLE:
            chars[i] = CONFUSABLE[chars[i]]
        elif kind == "digit" and chars[i].isdigit():
            chars[i] = str((int(chars[i]) + rng.randint(1, 9)) % 10)
        elif kind == "drop" and chars[i] in ".-," :
            del chars[i]
        else:
            continue
        out = "".join(chars)
        if out != text:
            return out


def exact_pair(rng: random.Random) -> dict:
    originals = [_record(rng) for _ in range(4)]
    pairs = [f"{o}  |  {o}" for o in originals[:1]] + [f"{o}  |  {_mutate(rng, o)}" for o in originals[1:]]
    answer, wrong = pairs[0], pairs[1:]
    return _q(
        rng, "exact_match",
        stem="Which pair is EXACTLY alike?",
        answer=answer,
        distractors=wrong,
        explanation=(
            f"Only \"{answer}\" matches character for character. Each other pair has one small difference "
            "(a swapped, changed or missing character); compare left to right, one character at a time."
        ),
        difficulty=1,
    )


def exact_copy(rng: random.Random) -> dict:
    original = _record(rng)
    copies: list[str] = []
    while len(copies) < 3:
        m = _mutate(rng, original)
        if m not in copies:
            copies.append(m)
    return _q(
        rng, "exact_match",
        stem=f"Which of the following is an exact copy of:\n{original}",
        answer=original,
        distractors=copies,
        explanation=f"Only \"{original}\" matches exactly. The others each contain one small copying error.",
        difficulty=1,
    )


def filing_order(rng: random.Random) -> dict:
    while True:
        # Shared surnames force the second and third sort keys to matter.
        surnames = rng.sample(SURNAMES, 3)
        people = {
            (rng.choice(surnames), rng.choice(GIVEN), rng.choice("ABCDEFGHJLMNPRSTV"))
            for _ in range(5)
        }
        if len(people) == 5 and len({p[0] for p in people}) < 5:
            break
    people = list(people)
    rng.shuffle(people)
    filed = sorted(people)
    place = rng.randrange(5)
    label = lambda p: f"{p[0]}, {p[1]} {p[2]}."  # noqa: E731
    ordinals = ["first", "second", "third", "fourth", "fifth"]
    return _q(
        rng, "filing_order",
        stem=(
            "Arrange these names in alphabetical filing order (surname, then first name, then middle initial):\n"
            + "\n".join(label(p) for p in people)
            + f"\nWhich name comes {ordinals[place]}?"
        ),
        answer=label(filed[place]),
        distractors=[label(p) for p in filed if p != filed[place]],
        explanation="Filing order: " + "; ".join(label(p) for p in filed),
        difficulty=2,
    )


GENERATORS: dict[str, Callable[[random.Random], dict]] = {
    "exact_match": lambda rng: (exact_pair if rng.random() < 0.5 else exact_copy)(rng),
    "filing_order": filing_order,
}
