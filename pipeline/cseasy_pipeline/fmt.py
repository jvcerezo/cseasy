"""Display formatting for generated choices, so equal values always render the same."""

from __future__ import annotations

from fractions import Fraction


def num(x: float | int | Fraction) -> str:
    """1234 -> '1,234'; 12.5 -> '12.5'; 2.333.. -> '2.33'."""
    if isinstance(x, Fraction):
        x = float(x)
    if float(x).is_integer():
        return f"{int(x):,}"
    return f"{x:,.2f}".rstrip("0").rstrip(".")


def peso(x: float | int) -> str:
    if float(x).is_integer():
        return f"₱{int(x):,}"
    return f"₱{x:,.2f}"


def pct(x: float | int) -> str:
    return f"{num(x)}%"


def frac(x: Fraction) -> str:
    """Fraction(7, 4) -> '7/4'; Fraction(3, 1) -> '3'."""
    if x.denominator == 1:
        return str(x.numerator)
    return f"{x.numerator}/{x.denominator}"


def unit(x: float | int, word: str) -> str:
    """unit(3, 'hours') -> '3 hours'; unit(1, 'hours') -> '1 hour'."""
    label = word[:-1] if float(x) == 1 and word.endswith("s") else word
    return f"{num(x)} {label}"
