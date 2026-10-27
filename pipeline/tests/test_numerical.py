import random
import re
import unittest
from fractions import Fraction

from cseasy_pipeline.generators import numerical
from cseasy_pipeline.schema import validate_question

SAMPLES_PER_GENERATOR = 400


class GeneratorInvariants(unittest.TestCase):
    def test_every_generated_question_is_valid(self):
        for topic, gen in numerical.GENERATORS.items():
            rng = random.Random(topic)
            for i in range(SAMPLES_PER_GENERATOR):
                q = {"id": f"t-{topic}-{i}", **gen(rng)}
                with self.subTest(topic=topic, i=i, stem=q["stem"]):
                    self.assertEqual(validate_question(q), [])
                    self.assertEqual(q["topic"], topic)
                    self.assertEqual(q["method"], "computed")

    def test_no_negative_choices(self):
        for topic, gen in numerical.GENERATORS.items():
            rng = random.Random(f"neg-{topic}")
            for _ in range(SAMPLES_PER_GENERATOR):
                q = gen(rng)
                for c in q["choices"]:
                    self.assertFalse(c.lstrip("₱").startswith("-"), f"{topic}: {q['stem']} -> {c}")


class IndependentChecks(unittest.TestCase):
    """Re-derive answers from the stem text alone, without the generator's math."""

    def _key(self, q):
        return q["choices"][q["answer"]]

    def test_arithmetic_and_geometric_series(self):
        rng = random.Random("series")
        checked = 0
        for _ in range(SAMPLES_PER_GENERATOR):
            q = numerical.number_series(rng)
            terms = [int(t) for t in re.findall(r"-?\d+", q["stem"].split("\n")[1])]
            diffs = {b - a for a, b in zip(terms, terms[1:])}
            ratios = {Fraction(b, a) for a, b in zip(terms, terms[1:]) if a}
            if len(diffs) == 1:
                self.assertEqual(self._key(q), f"{terms[-1] + diffs.pop():,}")
                checked += 1
            elif len(ratios) == 1:
                self.assertEqual(self._key(q), f"{int(terms[-1] * ratios.pop()):,}")
                checked += 1
        self.assertGreater(checked, 50)

    def test_simple_interest(self):
        rng = random.Random("si")
        checked = 0
        for _ in range(SAMPLES_PER_GENERATOR):
            q = numerical.interest(rng)
            m = re.match(r"How much simple interest does ₱([\d,]+) earn at (\d+)% per year for (\d+) years", q["stem"])
            if m:
                p, r, t = int(m[1].replace(",", "")), int(m[2]), int(m[3])
                self.assertEqual(self._key(q), f"₱{p * r * t // 100:,}")
                checked += 1
        self.assertGreater(checked, 50)

    def test_work_together(self):
        rng = random.Random("work")
        checked = 0
        for _ in range(SAMPLES_PER_GENERATOR):
            q = numerical.work(rng)
            m = re.search(r"in (\d+) hours, while \w+ can do it in (\d+) hours", q["stem"])
            if m:
                x, y = int(m[1]), int(m[2])
                t = 1 / (Fraction(1, x) + Fraction(1, y))
                self.assertEqual(t.denominator, 1)
                self.assertTrue(self._key(q).startswith(f"{t.numerator} hour"))
                checked += 1
        self.assertGreater(checked, 50)

    def test_round_trip_average_speed(self):
        rng = random.Random("trip")
        checked = 0
        for _ in range(SAMPLES_PER_GENERATOR):
            q = numerical.motion(rng)
            m = re.search(r"at (\d+) km/h and returns along the same road at (\d+) km/h", q["stem"])
            if m:
                a, b = int(m[1]), int(m[2])
                distance = a * b  # any equal one-way distance works
                avg = Fraction(2 * distance, Fraction(distance, a) + Fraction(distance, b))
                self.assertEqual(self._key(q), f"{avg.numerator} km/h")
                checked += 1
        self.assertGreater(checked, 50)


if __name__ == "__main__":
    unittest.main()
