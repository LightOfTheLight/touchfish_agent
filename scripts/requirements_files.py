#!/usr/bin/env python3
import re
import sys
from pathlib import Path

repo = Path(sys.argv[1]).resolve()
seed = ["REQUIREMENTS.md", "CICD_REQUIREMENTS.md", "AGENT_REQUIREMENTS.md"]

files = []

for name in seed:
    path = repo / name
    if not path.exists():
        continue
    files.append(path)
    try:
        text = path.read_text(encoding="utf-8", errors="ignore")
    except OSError:
        continue
    # Extract file-like tokens (simple heuristic).
    for match in re.findall(r"[A-Za-z0-9_./-]+\.[A-Za-z0-9_]+", text):
        candidate = (repo / match).resolve()
        if repo in candidate.parents or candidate == repo:
            if candidate.exists():
                files.append(candidate)

# Deduplicate while preserving order.
seen = set()
for path in files:
    if path in seen:
        continue
    seen.add(path)
    print(path)
