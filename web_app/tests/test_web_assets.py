import os
import unittest


ROOT = os.path.dirname(os.path.dirname(__file__))


class WebAssetsTests(unittest.TestCase):
    def test_expected_assets_exist(self):
        for rel in ("index.html", "main.js", "styles.css"):
            self.assertTrue(os.path.exists(os.path.join(ROOT, rel)))

    def test_index_contains_core_sections(self):
        with open(os.path.join(ROOT, "index.html"), "r", encoding="utf-8") as f:
            data = f.read()
        self.assertIn("Load Discover Feed", data)
        self.assertIn("Load Matches", data)
        self.assertIn("Load Threads", data)

    def test_js_targets_core_endpoints(self):
        with open(os.path.join(ROOT, "main.js"), "r", encoding="utf-8") as f:
            data = f.read()
        self.assertIn("/profiles/discover", data)
        self.assertIn("/matches/like", data)
        self.assertIn("/chat/threads", data)


if __name__ == "__main__":
    unittest.main()
