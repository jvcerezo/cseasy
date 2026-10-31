import os
import subprocess
import sys
import unittest
from pathlib import Path

PIPELINE = Path(__file__).resolve().parent.parent

# Prints a digest of every generated topic. Run under different hash seeds,
# the output must not change: generate.py promises a diff only when a
# generator changes, and shipped question ids must keep meaning the same item.
SCRIPT = """
import hashlib, json
from generate import SECTIONS, generate_topic
for section, (_, generators) in SECTIONS.items():
    for topic in generators:
        body = json.dumps(generate_topic(section, topic, 30), sort_keys=True)
        print(section, topic, hashlib.sha256(body.encode()).hexdigest())
"""


def _run(hash_seed: str) -> str:
    env = {**os.environ, "PYTHONHASHSEED": hash_seed}
    return subprocess.run(
        [sys.executable, "-c", SCRIPT], cwd=PIPELINE, env=env,
        capture_output=True, text=True, check=True,
    ).stdout


class Determinism(unittest.TestCase):
    def test_output_does_not_depend_on_hash_seed(self):
        first, second = _run("1"), _run("2")
        self.assertTrue(first.strip())
        mismatched = [a for a, b in zip(first.splitlines(), second.splitlines()) if a != b]
        self.assertEqual(mismatched, [], "generators iterate a set or dict in hash order")
