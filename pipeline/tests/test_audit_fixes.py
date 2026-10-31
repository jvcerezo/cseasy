"""Regressions for problems the 2026-10-31 content audit found in generated items."""

import random
import re
import unittest

from generate import dedup_key, generate_topic
from cseasy_pipeline.generators import numerical

SAMPLES = 400


def _many(gen, n=SAMPLES):
    rng = random.Random(7)
    return [gen(rng) for _ in range(n)]


class AuditFixes(unittest.TestCase):
    def test_age_explanation_never_repeats_the_last_step(self):
        for q in _many(numerical.age):
            self.assertNotRegex(q["explanation"], r"x = (\d+), x = \1\b", q["explanation"])

    def test_fraction_explanations_end_at_the_key(self):
        for q in _many(numerical.fractions):
            if q["stem"].startswith("Simplify"):
                key = q["choices"][q["answer"]]
                self.assertTrue(q["explanation"].endswith(f"= {key}."), q["explanation"])

    def test_fraction_addition_uses_the_least_common_denominator(self):
        for q in _many(numerical.fractions):
            m = re.search(r"least common denominator, (\d+)", q["explanation"])
            if m:
                a, b = (int(d) for d in re.findall(r"/(\d+)", q["stem"]))
                self.assertEqual(int(m.group(1)), a * b // __import__("math").gcd(a, b))

    def test_fill_and_drain_times_are_realistic(self):
        self.assertTrue(numerical.FILL_DRAIN)
        self.assertTrue(all(t <= 48 for _, _, t in numerical.FILL_DRAIN))

    def test_no_choice_is_zero_percent(self):
        for q in _many(numerical.percentage):
            self.assertNotIn("0%", q["choices"])

    def test_items_differing_only_in_names_are_duplicates(self):
        for section, topic in [("numerical", "work"), ("numerical", "age"), ("numerical", "distance_rate_time")]:
            keys = [dedup_key(q) for q in generate_topic(section, topic, 40)]
            self.assertEqual(len(keys), len(set(keys)), topic)
