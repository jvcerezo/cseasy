"""Numerical-ability generators for the CSE.

Every answer here is computed, never written by hand or by a model, so these
items skip the review gates. Each generator picks parameters that give clean
answers (whole numbers, round pesos) the way real exam items do, and builds
distractors from the mistakes test-takers actually make.
"""

from __future__ import annotations

import math
import random
from fractions import Fraction
from typing import Callable

from .. import fmt
from ..builder import computed_question

NAMES = [
    "Ana", "Ben", "Carlo", "Dina", "Ella", "Jun", "Liza",
    "Mark", "Nina", "Paolo", "Rico", "Tess", "Vince", "Joy",
]

ITEMS = [
    ("rice", "kilos"), ("eggs", "trays"), ("bond paper", "reams"),
    ("sugar", "kilos"), ("bottled water", "cases"), ("notebooks", "dozens"),
]


def _op(d: int) -> str:
    """6 -> '+ 6', -7 -> '− 7' for readable worked solutions."""
    return f"+ {d}" if d >= 0 else f"− {-d}"


def _q(rng: random.Random, topic: str, **kwargs) -> dict:
    return computed_question(rng, section="numerical", topic=topic, **kwargs)


# ---------------------------------------------------------------- number series

def number_series(rng: random.Random) -> dict:
    kind = rng.choice(["arithmetic", "geometric", "interleaved", "second_diff", "fibonacci"])

    if kind == "arithmetic":
        a, d = rng.randint(2, 60), rng.choice([-1, 1]) * rng.randint(3, 15)
        if d < 0:
            a += 10 * abs(d)  # keep every shown term positive
        terms = [a + i * d for i in range(6)]
        shown, ans = terms[:5], terms[5]
        explanation = f"Each term changes by {d:+d}. {shown[-1]} {_op(d)} = {ans}."
        distractors = [ans + d, ans + 1, ans - 2]
        difficulty = 1
    elif kind == "geometric":
        a, r = rng.randint(2, 6), rng.choice([2, 3])
        terms = [a * r**i for i in range(6)]
        shown, ans = terms[:5], terms[5]
        explanation = f"Each term is multiplied by {r}. {shown[-1]} × {r} = {ans}."
        distractors = [shown[-1] + (shown[-1] - shown[-2]), ans * r, ans - a]
        difficulty = 2
    elif kind == "interleaved":
        a1, d1 = rng.randint(1, 20), rng.randint(2, 9)
        a2, d2 = rng.randint(20, 60), rng.choice([-1, 1]) * rng.randint(2, 7)
        if d2 < 0:
            a2 += 5 * abs(d2)
        terms = []
        for i in range(4):
            terms += [a1 + i * d1, a2 + i * d2]
        shown, ans = terms[:7], terms[7]
        explanation = (
            "Two series alternate. Odd positions go "
            f"{a1}, {a1 + d1}, … ({d1:+d} each); even positions go "
            f"{a2}, {a2 + d2}, … ({d2:+d} each). The next term is in the even series: "
            f"{terms[5]} {_op(d2)} = {ans}."
        )
        distractors = [a1 + 4 * d1, ans + d2, shown[-1] + d1]
        difficulty = 2
    elif kind == "second_diff":
        a, d, c = rng.randint(1, 20), rng.randint(1, 6), rng.randint(1, 4)
        terms = [a]
        for i in range(6):
            terms.append(terms[-1] + d + i * c)
        shown, ans = terms[:6], terms[6]
        diffs = [shown[i + 1] - shown[i] for i in range(5)]
        next_diff = diffs[-1] + c
        explanation = (
            f"The differences are {', '.join(map(str, diffs))}, growing by {c} each time. "
            f"The next difference is {next_diff}, so {shown[-1]} + {next_diff} = {ans}."
        )
        distractors = [shown[-1] + diffs[-1], ans + c, ans - 1]
        difficulty = 3
    else:
        x, y = rng.randint(1, 9), rng.randint(2, 12)
        terms = [x, y]
        while len(terms) < 7:
            terms.append(terms[-1] + terms[-2])
        shown, ans = terms[:6], terms[6]
        explanation = (
            f"Each term is the sum of the two before it. {shown[-2]} + {shown[-1]} = {ans}."
        )
        distractors = [shown[-1] + (shown[-1] - shown[-2]), shown[-1] * 2, ans + 1]
        difficulty = 2

    return _q(
        rng,
        "number_series",
        stem=f"What is the next number in the series?\n{', '.join(map(str, shown))}, ___",
        answer=ans,
        distractors=distractors,
        explanation=explanation,
        difficulty=difficulty,
        fmt=fmt.num,
    )


# ------------------------------------------------------------------- percentage

NICE_PERCENTS = [5, 10, 12, 15, 20, 25, 30, 35, 40, 45, 60, 75, 80]


def percentage(rng: random.Random) -> dict:
    kind = rng.choice(["of", "discount", "successive", "what_percent", "increase"])

    if kind == "of":
        while True:
            p, base = rng.choice(NICE_PERCENTS), 20 * rng.randint(5, 100)
            if p * base % 100 == 0:
                break
        ans = p * base // 100
        return _q(
            rng, "percentage",
            stem=f"What is {p}% of {base:,}?",
            answer=ans,
            distractors=[base - ans, ans * 10, Fraction(ans, 10)],
            explanation=f"{p}% of {base:,} = {p}/100 × {base:,} = {ans:,}.",
            difficulty=1, fmt=fmt.num,
        )

    if kind == "discount":
        price, d = 100 * rng.randint(5, 100), rng.choice([10, 15, 20, 25, 30, 40])
        off = price * d // 100
        ans = price - off
        return _q(
            rng, "percentage",
            stem=f"A rice cooker priced at ₱{price:,} is sold at {d}% off. What is the sale price?",
            answer=ans,
            distractors=[off, price + off, price - d],
            explanation=f"Discount = {d}% × ₱{price:,} = ₱{off:,}. Sale price = ₱{price:,} − ₱{off:,} = ₱{ans:,}.",
            difficulty=1, fmt=fmt.peso, filler_step=50,
        )

    if kind == "successive":
        while True:
            price = 100 * rng.randint(10, 100)
            a, b = rng.sample([10, 15, 20, 25, 30], 2)
            if price * (100 - a) * (100 - b) % 10000 == 0:
                break
        after_a = price * (100 - a) // 100
        ans = after_a * (100 - b) // 100
        return _q(
            rng, "percentage",
            stem=(
                f"A store marks down a ₱{price:,} jacket by {a}%, then takes another "
                f"{b}% off the reduced price. What is the final price?"
            ),
            answer=ans,
            distractors=[price * (100 - a - b) // 100, after_a, price * (100 - b) // 100],
            explanation=(
                f"After {a}% off: ₱{price:,} × {100 - a}% = ₱{after_a:,}. "
                f"After another {b}% off: ₱{after_a:,} × {100 - b}% = ₱{ans:,}. "
                f"Successive discounts do not simply add up to {a + b}%."
            ),
            difficulty=2, fmt=fmt.peso, filler_step=50,
        )

    if kind == "what_percent":
        while True:
            p, whole = rng.choice(NICE_PERCENTS), 20 * rng.randint(3, 60)
            if p * whole % 100 == 0:
                break
        part = p * whole // 100
        return _q(
            rng, "percentage",
            stem=f"{part:,} is what percent of {whole:,}?",
            answer=p,
            distractors=[100 - p, p * 10, Fraction(p, 10), p * 2],
            explanation=f"{part:,} ÷ {whole:,} = {p / 100:g}, which is {p}%.",
            difficulty=1, fmt=fmt.pct, filler_step=5,
        )

    while True:
        old, p = 20 * rng.randint(5, 100), rng.choice([10, 20, 25, 40, 50, 60, 75])
        if old * p % 100 == 0:
            break
    new = old + old * p // 100
    wrong_base = Fraction((new - old) * 100, new)
    return _q(
        rng, "percentage",
        stem=f"A worker's daily wage went up from ₱{old:,} to ₱{new:,}. What is the percent increase?",
        answer=p,
        distractors=[wrong_base, p + 10, Fraction(p, 2)],
        explanation=(
            f"Increase = ₱{new - old:,}. Divide by the ORIGINAL wage: "
            f"{new - old:,} ÷ {old:,} = {p / 100:g}, so {p}%."
        ),
        difficulty=2, fmt=fmt.pct, filler_step=5,
    )


# ------------------------------------------------------------- ratio/proportion

def ratio(rng: random.Random) -> dict:
    kind = rng.choice(["split", "direct", "inverse"])

    if kind == "split":
        n = rng.choice([2, 3])
        parts = rng.sample(range(1, 8), n)
        people = rng.sample(NAMES, n)
        unit_amount = rng.choice([50, 100, 200, 250, 500])
        total = sum(parts) * unit_amount
        i = rng.randrange(n)
        ans = parts[i] * unit_amount
        others = [p * unit_amount for j, p in enumerate(parts) if j != i]
        ratio_text = ":".join(map(str, parts))
        return _q(
            rng, "ratio_proportion",
            stem=(
                f"{', '.join(people[:-1])} and {people[-1]} share ₱{total:,} in the ratio "
                f"{ratio_text}. How much does {people[i]} get?"
            ),
            answer=ans,
            distractors=[*others, Fraction(total, n)],
            explanation=(
                f"Total parts = {' + '.join(map(str, parts))} = {sum(parts)}. "
                f"One part = ₱{total:,} ÷ {sum(parts)} = ₱{unit_amount:,}. "
                f"{people[i]} gets {parts[i]} × ₱{unit_amount:,} = ₱{ans:,}."
            ),
            difficulty=2, fmt=fmt.peso, filler_step=unit_amount,
        )

    if kind == "direct":
        item, unit_word = rng.choice(ITEMS)
        k1, k2 = rng.sample(range(2, 12), 2)
        each = 5 * rng.randint(6, 60)
        cost = k1 * each
        ans = k2 * each
        return _q(
            rng, "ratio_proportion",
            stem=f"If {k1} {unit_word} of {item} cost ₱{cost:,}, how much do {k2} {unit_word} cost?",
            answer=ans,
            distractors=[cost * k2, ans + each, cost + (k2 - k1)],
            explanation=f"One costs ₱{cost:,} ÷ {k1} = ₱{each:,}. So {k2} cost {k2} × ₱{each:,} = ₱{ans:,}.",
            difficulty=1, fmt=fmt.peso, filler_step=each,
        )

    while True:
        w1, d1 = rng.randint(3, 12), rng.randint(4, 30)
        w2 = rng.randint(2, 20)
        if w2 != w1 and w1 * d1 % w2 == 0:
            break
    ans = w1 * d1 // w2
    return _q(
        rng, "ratio_proportion",
        stem=(
            f"{w1} workers can paint a school building in {d1} days. Working at the same rate, "
            f"how many days would {w2} workers take?"
        ),
        answer=ans,
        distractors=[Fraction(d1 * w2, w1), d1 + (w1 - w2), ans + 1],
        explanation=(
            f"More workers means fewer days (inverse proportion). The job is {w1} × {d1} = "
            f"{w1 * d1} worker-days, so {w1 * d1} ÷ {w2} = {ans} days."
        ),
        difficulty=2, fmt=lambda x: fmt.unit(x, "days"),
    )


# ------------------------------------------------------------------- work rate

def _clean_pairs(limit: int, combine: Callable[[int, int], Fraction]) -> list[tuple[int, int, int]]:
    pairs = []
    for x in range(2, limit):
        for y in range(x + 1, limit):
            t = combine(x, y)
            if t > 0 and t.denominator == 1:
                pairs.append((x, y, t.numerator))
    return pairs


TOGETHER = _clean_pairs(61, lambda x, y: Fraction(x * y, x + y))
# Fill times capped at two days: a drain almost as fast as the inlet gives
# technically right but absurd answers (hundreds of hours).
FILL_DRAIN = [p for p in _clean_pairs(61, lambda x, y: Fraction(x * y, y - x)) if p[2] <= 48]


def work(rng: random.Random) -> dict:
    a, b = rng.sample(NAMES, 2)
    if rng.random() < 0.6:
        x, y, t = rng.choice(TOGETHER)
        return _q(
            rng, "work",
            stem=(
                f"{a} can encode a batch of records in {x} hours, while {b} can do it in {y} hours. "
                "How long will it take them working together?"
            ),
            answer=t,
            distractors=[Fraction(x + y, 2), x + y, y - x],
            explanation=(
                f"Rates add: 1/{x} + 1/{y} = {fmt.frac(Fraction(1, x) + Fraction(1, y))} of the job per hour. "
                f"Time = 1 ÷ {fmt.frac(Fraction(1, x) + Fraction(1, y))} = {t} hours."
            ),
            difficulty=2, fmt=lambda v: fmt.unit(v, "hours"),
        )

    x, y, t = rng.choice(FILL_DRAIN)
    net = Fraction(1, x) - Fraction(1, y)
    return _q(
        rng, "work",
        stem=(
            f"An inlet pipe fills a tank in {x} hours. A drain empties the full tank in {y} hours. "
            "If both are open, how long will it take to fill the empty tank?"
        ),
        answer=t,
        distractors=[Fraction(x * y, x + y), y - x, x + y],
        explanation=(
            f"Net rate = 1/{x} − 1/{y} = {fmt.frac(net)} of the tank per hour. "
            f"Time = 1 ÷ {fmt.frac(net)} = {t} hours."
        ),
        difficulty=3, fmt=lambda v: fmt.unit(v, "hours"),
    )


# ------------------------------------------------------------------- motion

# Speeds stay multiples of 5 so the stems read like real road speeds.
ROUND_TRIPS = [
    (x, y, avg)
    for x, y, avg in _clean_pairs(91, lambda x, y: Fraction(2 * x * y, x + y))
    if x % 5 == 0 and y % 5 == 0 and x >= 20  # no walking-pace trips
]


def motion(rng: random.Random) -> dict:
    kind = rng.choice(["round_trip", "meeting", "basic"])

    if kind == "round_trip":
        a, b, avg = rng.choice(ROUND_TRIPS)
        if rng.random() < 0.5:
            a, b = b, a
        return _q(
            rng, "distance_rate_time",
            stem=(
                f"A car travels from town A to town B at {a} km/h and returns along the same road "
                f"at {b} km/h. What is its average speed for the whole trip?"
            ),
            answer=avg,
            distractors=[Fraction(a + b, 2), a + b, avg + 5],
            explanation=(
                "Average speed = total distance ÷ total time, not the average of the two speeds. "
                f"For equal distances it is 2 × {a} × {b} ÷ ({a} + {b}) = {avg} km/h."
            ),
            difficulty=3, fmt=lambda v: f"{fmt.num(v)} km/h", filler_step=5,
        )

    if kind == "meeting":
        while True:
            s1, s2 = 5 * rng.randint(6, 16), 5 * rng.randint(6, 16)
            t = rng.randint(2, 6)
            if s1 != s2:
                break
        d = (s1 + s2) * t
        return _q(
            rng, "distance_rate_time",
            stem=(
                f"Two buses leave towns {d} km apart at the same time and drive toward each other, "
                f"one at {s1} km/h and the other at {s2} km/h. After how many hours do they meet?"
            ),
            answer=t,
            distractors=[Fraction(d, abs(s1 - s2)), Fraction(d, max(s1, s2)), t + 1],
            explanation=f"They close the gap at {s1} + {s2} = {s1 + s2} km/h. Time = {d} ÷ {s1 + s2} = {t} hours.",
            difficulty=2, fmt=lambda v: fmt.unit(v, "hours"),
        )

    speed = 10 * rng.randint(3, 9)
    minutes = rng.choice([15, 30, 45, 90, 105, 150])
    ans = Fraction(speed * minutes, 60)
    return _q(
        rng, "distance_rate_time",
        stem=f"A car travels at a steady {speed} km/h for {minutes} minutes. How far does it go?",
        answer=ans,
        distractors=[speed * minutes, Fraction(speed * minutes, 100), speed],
        explanation=f"{minutes} minutes = {fmt.num(Fraction(minutes, 60))} hours. Distance = {speed} × {fmt.num(Fraction(minutes, 60))} = {fmt.num(ans)} km.",
        difficulty=1, fmt=lambda v: f"{fmt.num(v)} km", filler_step=5,
    )


# ------------------------------------------------------------------- age

def age(rng: random.Random) -> dict:
    a, b = rng.sample(NAMES, 2)
    if rng.random() < 0.5:
        while True:
            k, m = rng.randint(3, 6), rng.randint(2, 4)
            n = rng.randint(2, 15)
            if k > m and n * (m - 1) % (k - m) == 0:
                younger = n * (m - 1) // (k - m)
                if 2 <= younger <= 20:
                    break
        older = k * younger
        return _q(
            rng, "age",
            stem=(
                f"{a} is {k} times as old as {b}. In {n} years, {a} will be {m} times as old as {b}. "
                f"How old is {a} now?"
            ),
            answer=older,
            distractors=[younger, older + n, k * (younger + n)],
            explanation=(
                f"Let {b} = x, so {a} = {k}x. In {n} years: {k}x + {n} = {m}(x + {n}). "
                + (f"So x = {younger}. " if k - m == 1 else f"So {k - m}x = {n * (m - 1)}, x = {younger}. ")
                + f"{a} is {k} × {younger} = {older}."
            ),
            difficulty=3, fmt=fmt.num,
        )

    while True:
        gap, total = rng.randint(2, 15), rng.randint(20, 90)
        if (total + gap) % 2 == 0 and total > gap + 2:
            break
    older = (total + gap) // 2
    return _q(
        rng, "age",
        stem=f"{a} is {gap} years older than {b}. The sum of their ages is {total}. How old is {a}?",
        answer=older,
        distractors=[older - gap, Fraction(total, 2), total - gap],
        explanation=(
            f"Let {b} = x, so {a} = x + {gap}. Then 2x + {gap} = {total}, x = {older - gap}, "
            f"and {a} is {older - gap} + {gap} = {older}."
        ),
        difficulty=1, fmt=fmt.num,
    )


# ------------------------------------------------------------------- interest

def interest(rng: random.Random) -> dict:
    kind = rng.choice(["simple", "maturity", "compound"])

    if kind in ("simple", "maturity"):
        while True:
            p = 1000 * rng.randint(5, 200)
            r, t = rng.randint(2, 12), rng.randint(2, 5)
            if p * r * t % 100 == 0:
                break
        i = p * r * t // 100
        if kind == "simple":
            return _q(
                rng, "interest",
                stem=f"How much simple interest does ₱{p:,} earn at {r}% per year for {t} years?",
                answer=i,
                distractors=[p * r // 100, p + i, i * 2],
                explanation=f"I = P × r × t = ₱{p:,} × {r}% × {t} = ₱{i:,}.",
                difficulty=1, fmt=fmt.peso, filler_step=100,
            )
        return _q(
            rng, "interest",
            stem=(
                f"Ana borrows ₱{p:,} from a cooperative at {r}% simple interest per year. "
                f"How much does she pay back in total after {t} years?"
            ),
            answer=p + i,
            distractors=[i, p + p * r // 100, p + 2 * i],
            explanation=f"Interest = ₱{p:,} × {r}% × {t} = ₱{i:,}. Total = ₱{p:,} + ₱{i:,} = ₱{p + i:,}.",
            difficulty=2, fmt=fmt.peso, filler_step=100,
        )

    p, r = 10_000 * rng.randint(1, 20), rng.choice([2, 4, 5, 6, 8, 10])
    after1 = p * (100 + r) // 100
    ans = p * (100 + r) ** 2 // 10_000
    simple = p + 2 * p * r // 100
    return _q(
        rng, "interest",
        stem=f"₱{p:,} is deposited at {r}% interest compounded annually. How much is in the account after 2 years?",
        answer=ans,
        distractors=[simple, after1, ans + p * r // 100],
        explanation=(
            f"Year 1: ₱{p:,} × {1 + r / 100:g} = ₱{after1:,}. "
            f"Year 2: ₱{after1:,} × {1 + r / 100:g} = ₱{ans:,}. "
            f"(Simple interest would give only ₱{simple:,}.)"
        ),
        difficulty=2, fmt=fmt.peso, filler_step=100,
    )


# ------------------------------------------------------------------- averages

def average(rng: random.Random) -> dict:
    kind = rng.choice(["remove", "needed", "list"])

    if kind == "remove":
        while True:
            n, avg = rng.randint(4, 9), rng.randint(20, 90)
            x = rng.randint(5, 120)
            if (n * avg - x) % (n - 1) == 0 and x != avg:
                break
        ans = (n * avg - x) // (n - 1)
        return _q(
            rng, "averages",
            stem=f"The average of {n} numbers is {avg}. If the number {x} is removed, what is the average of the remaining numbers?",
            answer=ans,
            distractors=[Fraction(n * avg - x, n), avg, avg - Fraction(x, n)],
            explanation=(
                f"Sum = {n} × {avg} = {n * avg}. Remove {x}: {n * avg - x}. "
                f"New average = {n * avg - x} ÷ {n - 1} = {ans}."
            ),
            difficulty=2, fmt=fmt.num,
        )

    if kind == "needed":
        while True:
            k, cur = rng.randint(2, 5), rng.randint(70, 88)
            target = cur + rng.randint(1, 5)
            need = target * (k + 1) - k * cur
            if need <= 100:
                break
        return _q(
            rng, "averages",
            stem=(
                f"Jun's average on {k} quizzes is {cur}. What score does he need on the next quiz "
                f"to raise his average to {target}?"
            ),
            answer=need,
            distractors=[target, 2 * target - cur, target + (target - cur)],
            explanation=(
                f"He needs a total of {target} × {k + 1} = {target * (k + 1)}. He has {k} × {cur} = {k * cur}. "
                f"Needed = {target * (k + 1)} − {k * cur} = {need}."
            ),
            difficulty=2, fmt=fmt.num,
        )

    while True:
        values = [rng.randint(10, 99) for _ in range(5)]
        if sum(values) % 5 == 0:
            break
    ans = sum(values) // 5
    median = sorted(values)[2]
    return _q(
        rng, "averages",
        stem=f"What is the average of {', '.join(map(str, values[:-1]))} and {values[-1]}?",
        answer=ans,
        distractors=[median, Fraction(sum(values), 4), ans + 2],
        explanation=f"Sum = {sum(values)}. Average = {sum(values)} ÷ 5 = {ans}.",
        difficulty=1, fmt=fmt.num,
    )


# ------------------------------------------------------------------- fractions

def _reduce_step(num: int, den: int) -> str:
    """"num/den", followed by its lowest terms when that differs."""
    raw = f"{num}/{den}"
    reduced = fmt.frac(Fraction(num, den))
    return raw if reduced == raw else f"{raw} = {reduced}"


def _add_explanation(x: Fraction, y: Fraction) -> str:
    lcd = math.lcm(x.denominator, y.denominator)
    a, b = x.numerator * (lcd // x.denominator), y.numerator * (lcd // y.denominator)
    return (
        f"Use the least common denominator, {lcd}: {fmt.frac(x)} + {fmt.frac(y)} = "
        f"{a}/{lcd} + {b}/{lcd} = " + _reduce_step(a + b, lcd) + "."
    )


def fractions(rng: random.Random) -> dict:
    kind = rng.choice(["add", "multiply", "divide", "order_of_operations"])

    if kind == "order_of_operations":
        while True:
            a, b, c, d, e = (rng.randint(2, 12) for _ in range(5))
            if d % e == 0:
                break
        ans = a + b * c - d // e
        left_to_right = Fraction(((a + b) * c - d), e)
        return _q(
            rng, "fractions_operations",
            stem=f"Evaluate: {a} + {b} × {c} − {d} ÷ {e}",
            answer=ans,
            distractors=[left_to_right, (a + b) * c - d // e, a + b * c - d],
            explanation=(
                f"Multiply and divide first: {b} × {c} = {b * c} and {d} ÷ {e} = {d // e}. "
                f"Then {a} + {b * c} − {d // e} = {ans}."
            ),
            difficulty=1, fmt=fmt.num,
        )

    while True:
        x = Fraction(rng.randint(1, 9), rng.randint(2, 9))
        y = Fraction(rng.randint(1, 9), rng.randint(2, 9))
        if x.denominator != 1 and y.denominator != 1 and x != y:
            break
    xs, ys = fmt.frac(x), fmt.frac(y)

    if kind == "add":
        ans = x + y
        return _q(
            rng, "fractions_operations",
            stem=f"Simplify: {xs} + {ys}",
            answer=ans,
            distractors=[
                Fraction(x.numerator + y.numerator, x.denominator + y.denominator),
                x * y,
                Fraction(x.numerator + y.numerator, x.denominator * y.denominator),
            ],
            explanation=_add_explanation(x, y),
            difficulty=1, fmt=fmt.frac, filler_step=Fraction(1, ans.denominator),
        )

    if kind == "multiply":
        ans = x * y
        return _q(
            rng, "fractions_operations",
            stem=f"Simplify: {xs} × {ys}",
            answer=ans,
            distractors=[x / y, x + y, Fraction(x.numerator * y.numerator, x.denominator + y.denominator)],
            explanation=(
                f"Multiply across: ({x.numerator} × {y.numerator}) / ({x.denominator} × {y.denominator}) = "
                + _reduce_step(x.numerator * y.numerator, x.denominator * y.denominator) + "."
            ),
            difficulty=1, fmt=fmt.frac, filler_step=Fraction(1, ans.denominator),
        )

    ans = x / y
    return _q(
        rng, "fractions_operations",
        stem=f"Simplify: {xs} ÷ {ys}",
        answer=ans,
        distractors=[x * y, y / x, x - y],
        explanation=(
            f"Multiply by the reciprocal: {xs} × {y.denominator}/{y.numerator} = "
            + _reduce_step(x.numerator * y.denominator, x.denominator * y.numerator) + "."
        ),
        difficulty=2, fmt=fmt.frac, filler_step=Fraction(1, ans.denominator),
    )


# ------------------------------------------------------------ consecutive ints

def consecutive(rng: random.Random) -> dict:
    n = rng.choice([3, 4, 5])
    step, label = rng.choice([(1, "consecutive integers"), (2, "consecutive even integers"), (2, "consecutive odd integers")])
    start = rng.randint(5, 60)
    if label.endswith("even integers") and start % 2:
        start += 1
    if label.endswith("odd integers") and start % 2 == 0:
        start += 1
    nums = [start + i * step for i in range(n)]
    total = sum(nums)
    ask_largest = rng.random() < 0.5
    ans = nums[-1] if ask_largest else nums[0]
    which = "largest" if ask_largest else "smallest"
    return _q(
        rng, "consecutive_integers",
        stem=f"The sum of {n} {label} is {total}. What is the {which}?",
        answer=ans,
        distractors=[nums[0] if ask_largest else nums[-1], Fraction(total, n), ans + step if ask_largest else ans - step],
        explanation=(
            f"The middle value is {total} ÷ {n} = {fmt.num(Fraction(total, n))}, so the numbers are "
            f"{', '.join(map(str, nums))}. The {which} is {ans}."
        ),
        difficulty=2, fmt=fmt.num, filler_step=step,
    )


GENERATORS: dict[str, Callable[[random.Random], dict]] = {
    "number_series": number_series,
    "percentage": percentage,
    "ratio_proportion": ratio,
    "work": work,
    "distance_rate_time": motion,
    "age": age,
    "interest": interest,
    "averages": average,
    "fractions_operations": fractions,
    "consecutive_integers": consecutive,
}
