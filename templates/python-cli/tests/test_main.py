"""Tests for the generated CLI; run with python -m unittest discover -s tests."""

import contextlib
import io
import unittest

from main import main


class MainTests(unittest.TestCase):
    def test_greets_named_person(self):
        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            result = main(["Ada"])
        self.assertEqual(result, 0)
        self.assertEqual(output.getvalue(), "Hello, Ada!\n")


if __name__ == "__main__":
    unittest.main()
