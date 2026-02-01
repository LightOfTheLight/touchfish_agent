from pathlib import Path
import unittest


class DocumentationRequirementsTests(unittest.TestCase):
    def test_build_doc_exists_and_has_content(self):
        repo_root = Path(__file__).resolve().parents[1]
        build_doc = repo_root / "BUILD.md"
        self.assertTrue(build_doc.exists())
        self.assertGreater(len(build_doc.read_text(encoding="utf-8").strip()), 0)

    def test_usage_doc_exists_and_has_content(self):
        repo_root = Path(__file__).resolve().parents[1]
        usage_doc = repo_root / "USAGE.md"
        self.assertTrue(usage_doc.exists())
        self.assertGreater(len(usage_doc.read_text(encoding="utf-8").strip()), 0)


if __name__ == "__main__":
    unittest.main()
