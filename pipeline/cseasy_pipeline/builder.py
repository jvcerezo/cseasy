"""Turns a computed answer plus mistake-based distractors into a schema question."""

from __future__ import annotations

import random
from typing import Callable

from .schema import CHOICE_COUNT

Formatter = Callable[[object], str]


def computed_question(
    rng: random.Random,
    *,
    section: str,
    topic: str,
    stem: str,
    answer: object,
    distractors: list[object],
    explanation: str,
    difficulty: int,
    fmt: Formatter,
    levels: tuple[str, ...] = ("professional", "subprofessional"),
    filler_step: int | float = 1,
) -> dict:
    """Build a question whose key is `answer`.

    `distractors` should model real mistakes (wrong formula, a skipped step).
    Ones that collide with the answer or each other once formatted are dropped,
    and the gap is filled with near misses `answer ± k * filler_step` so every
    question still has exactly four distinct choices.
    """
    correct = fmt(answer)
    picked: list[str] = []
    for d in distractors:
        text = fmt(d)
        if text != correct and text not in picked and _is_sane(d):
            picked.append(text)
        if len(picked) == CHOICE_COUNT - 1:
            break

    k = 1
    while len(picked) < CHOICE_COUNT - 1:
        for candidate in (answer + k * filler_step, answer - k * filler_step):
            text = fmt(candidate)
            if _is_sane(candidate) and text != correct and text not in picked:
                picked.append(text)
                if len(picked) == CHOICE_COUNT - 1:
                    break
        k += 1

    choices = [correct, *picked]
    rng.shuffle(choices)
    return {
        "exam": "cse",
        "levels": list(levels),
        "section": section,
        "topic": topic,
        "stem": stem,
        "choices": choices,
        "answer": choices.index(correct),
        "explanation": explanation,
        "source": None,
        "method": "computed",
        "status": "verified",
        "difficulty": difficulty,
    }


def _is_sane(value: object) -> bool:
    # Negative amounts, ages or speeds read as obvious throwaways.
    try:
        return value >= 0  # type: ignore[operator]
    except TypeError:
        return True
