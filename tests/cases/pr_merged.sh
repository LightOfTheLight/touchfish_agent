TEST_NAME="PR merged"

EXPECTED_COMPACT_MARKER="compacted"

run_case() {
  local repo="$TEST_TMP/repo_pr"
  local remote="$TEST_TMP/remote_pr.git"
  setup_repo "$repo" "$remote"

  echo "base" > "$repo/file.txt"
  git -C "$repo" add file.txt
  git -C "$repo" commit -m "base" >/dev/null
  git -C "$repo" push -u origin HEAD >/dev/null

  local gh_log="$TEST_TMP/gh_pr.log"
  export GH_CALL_LOG="$gh_log"
  export GH_PR_MERGED=true

  local compact_log="$TEST_TMP/compact.log"
  local compact_script="$TEST_TMP/compact.sh"
  cat <<'SH' > "$compact_script"
#!/usr/bin/env bash
set -euo pipefail
echo "compacted" >> "$1"
SH
  chmod +x "$compact_script"
  export CODEX_COMPACT_CMD="$compact_script $compact_log"

  export AGENT_LIBRARY_MODE=1
  export AGENT_NAME="unit_agent"
  export GITHUB_TOKEN="dummy"
  export REPO_URL="file://$remote"
  export REPO_DIR="$repo"
  export POLL_INTERVAL=1

  # shellcheck source=/dev/null
  source "$ROOT_DIR/scripts/agent.sh"

  session_loop 55 "agent/unit_agent/test" "main"

  if [[ ! -f "$compact_log" ]]; then
    echo "Expected compact log not created" >&2
    return 1
  fi

  if ! grep -q "$EXPECTED_COMPACT_MARKER" "$compact_log"; then
    echo "Expected compact marker not found" >&2
    return 1
  fi
}
