import subprocess
import sys
import tempfile
from pathlib import Path
import unittest


class RequirementsFilesTests(unittest.TestCase):
    def test_discovers_seed_and_referenced_files(self):
        with tempfile.TemporaryDirectory() as tmp:
            repo = Path(tmp)
            (repo / "docs").mkdir(parents=True, exist_ok=True)
            (repo / "REQUIREMENTS.md").write_text(
                "See docs/EXTRA.md and missing/NOPE.md\n", encoding="utf-8"
            )
            (repo / "CICD_REQUIREMENTS.md").write_text("cicd", encoding="utf-8")
            (repo / "AGENT_REQUIREMENTS.md").write_text("agent", encoding="utf-8")
            (repo / "docs" / "EXTRA.md").write_text("extra", encoding="utf-8")

            repo_root = Path(__file__).resolve().parents[1]
            script = repo_root / "scripts" / "requirements_files.py"

            result = subprocess.run(
                [sys.executable, str(script), str(repo)],
                check=True,
                capture_output=True,
                text=True,
            )

            output_paths = {Path(line.strip()) for line in result.stdout.splitlines() if line.strip()}

            self.assertIn((repo / "REQUIREMENTS.md").resolve(), output_paths)
            self.assertIn((repo / "CICD_REQUIREMENTS.md").resolve(), output_paths)
            self.assertIn((repo / "AGENT_REQUIREMENTS.md").resolve(), output_paths)
            self.assertIn((repo / "docs" / "EXTRA.md").resolve(), output_paths)
            self.assertNotIn((repo / "missing" / "NOPE.md").resolve(), output_paths)


if __name__ == "__main__":
    unittest.main()
