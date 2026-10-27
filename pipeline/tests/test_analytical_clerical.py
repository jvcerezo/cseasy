import random
import re
import unittest

from cseasy_pipeline.generators import analytical, clerical
from cseasy_pipeline.generators.analytical import ALL, NO, SOME, SOME_NOT, _follows
from cseasy_pipeline.schema import validate_question

SAMPLES = 300
A, B, C = 0, 1, 2


class Invariants(unittest.TestCase):
    def test_every_generated_question_is_valid(self):
        for module, section in ((analytical, "analytical"), (clerical, "clerical")):
            for topic, gen in module.GENERATORS.items():
                rng = random.Random(topic)
                for i in range(SAMPLES):
                    q = {"id": f"t-{topic}-{i}", **gen(rng)}
                    with self.subTest(topic=topic, i=i):
                        self.assertEqual(validate_question(q), [], q["stem"])
                        self.assertEqual(q["section"], section)


class SyllogismEngine(unittest.TestCase):
    """Classical forms with textbook answers."""

    def test_barbara(self):
        premises = [(ALL, A, B), (ALL, B, C)]
        for e in (False, True):
            self.assertTrue(_follows(premises, (ALL, A, C), e))

    def test_celarent(self):
        premises = [(ALL, A, B), (NO, B, C)]
        self.assertTrue(_follows(premises, (NO, A, C), False))

    def test_darii(self):
        premises = [(SOME, A, B), (ALL, B, C)]
        self.assertTrue(_follows(premises, (SOME, A, C), False))

    def test_undistributed_middle_is_invalid(self):
        premises = [(ALL, A, B), (ALL, C, B)]
        for e in (False, True):
            self.assertFalse(_follows(premises, (ALL, A, C), e))
            self.assertFalse(_follows(premises, (SOME, A, C), e))

    def test_existential_import_case_differs(self):
        # Darapti: valid only if the groups are assumed to exist, so the
        # generator must never use it as a key.
        premises = [(ALL, B, A), (ALL, B, C)]
        self.assertFalse(_follows(premises, (SOME, A, C), False))
        self.assertTrue(_follows(premises, (SOME, A, C), True))

    def test_some_not(self):
        premises = [(SOME_NOT, A, B), (ALL, C, B)]
        self.assertTrue(_follows(premises, (SOME_NOT, A, C), False))


class IndependentChecks(unittest.TestCase):
    def test_calendar_offsets(self):
        days = analytical.DAYS
        rng = random.Random("cal")
        for _ in range(SAMPLES):
            q = analytical.calendar(rng)
            m = re.match(r"Today is (\w+)\. What day of the week will it be (\d+) days", q["stem"])
            if m:
                expected = days[(days.index(m[1]) + int(m[2])) % 7]
                self.assertEqual(q["choices"][q["answer"]], expected)

    def test_filing_order_matches_sorted(self):
        rng = random.Random("file")
        ordinals = ["first", "second", "third", "fourth", "fifth"]
        for _ in range(SAMPLES):
            q = clerical.filing_order(rng)
            lines = q["stem"].split("\n")[1:6]
            place = ordinals.index(re.search(r"comes (\w+)\?", q["stem"])[1])
            key = lambda s: tuple(re.match(r"(\w+), (\w+) (\w)\.", s).groups())  # noqa: E731
            self.assertEqual(q["choices"][q["answer"]], sorted(lines, key=key)[place])

    def test_exact_copy_has_one_true_copy(self):
        rng = random.Random("copy")
        for _ in range(SAMPLES):
            q = clerical.exact_copy(rng)
            original = q["stem"].split("\n", 1)[1]
            self.assertEqual([c for c in q["choices"] if c == original], [q["choices"][q["answer"]]])


if __name__ == "__main__":
    unittest.main()
