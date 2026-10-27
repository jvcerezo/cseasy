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
    def test_filing_order_matches_sorted(self):
        rng = random.Random("file")
        ordinals = ["first", "second", "third", "fourth", "fifth"]
        for _ in range(SAMPLES):
            q = clerical.filing_order(rng)
            lines = q["stem"].split("\n")[1:6]
            place = ordinals.index(re.search(r"comes (\w+)\?", q["stem"])[1])
            key = lambda s: tuple(re.match(r"(\w+), (\w+) (\w)\.", s).groups())  # noqa: E731
            self.assertEqual(q["choices"][q["answer"]], sorted(lines, key=key)[place])

    def test_misspellings_are_never_real_entries(self):
        words = set(clerical.MISSPELLINGS)
        for word, wrong in clerical.MISSPELLINGS.items():
            with self.subTest(word=word):
                self.assertEqual(len(set(wrong)), 3)
                self.assertFalse(set(wrong) & words)
                self.assertNotIn(word, wrong)

    def test_spelling_has_exactly_one_key(self):
        words = set(clerical.MISSPELLINGS)
        rng = random.Random("spell")
        for _ in range(SAMPLES):
            q = clerical.GENERATORS["spelling"](rng)
            key = q["choices"][q["answer"]]
            correct = [c for c in q["choices"] if c in words]
            if q["stem"].startswith("Which word is spelled correctly"):
                self.assertEqual(correct, [key])
            else:
                self.assertEqual(len(correct), 3)
                self.assertNotIn(key, words)

    def test_symbolic_logic_textbook_answers(self):
        negate = {pos: neg for pos, neg in analytical.CLAUSES} | {neg: pos for pos, neg in analytical.CLAUSES}
        cap = lambda t: t[0].upper() + t[1:] + "."  # noqa: E731
        rng = random.Random("logic")
        for _ in range(SAMPLES):
            q = analytical.symbolic_logic(rng)
            key = q["choices"][q["answer"]]
            m = re.search(r'means the same as: "If (.+), then (.+)\."', q["stem"])
            if m:
                self.assertEqual(key, f"If {negate[m[2]]}, then {negate[m[1]]}.")
                continue
            lines = q["stem"].split("\n")[1:-1]
            rules = [re.match(r"If (.+), then (.+)\.$", line) for line in lines[:-1]]
            fact = lines[-1]
            if all(rules) and len(rules) == 1:
                p_, q_ = rules[0][1], rules[0][2]
                expected = {
                    cap(p_): cap(q_),                  # modus ponens
                    cap(negate[q_]): cap(negate[p_]),  # modus tollens
                }.get(fact, analytical.NONE_FOLLOWS)   # affirming / denying: nothing follows
                self.assertEqual(key, expected)
            elif all(rules):
                (p_, q1), (q2, r_) = rules[0].groups(), rules[1].groups()
                self.assertEqual(q1, q2)
                self.assertEqual(key, cap(r_) if fact == cap(p_) else cap(negate[p_]))
            else:
                either = re.match(r"Either (.+) or (.+) \(or both\)\.$", lines[0])
                self.assertEqual(key, cap(either[2]))


if __name__ == "__main__":
    unittest.main()
