#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
REPORT_PATH=${TEST_REPORT:-"$ROOT_DIR/tests/report.txt"}

run_in_container() {
  if ! command -v docker >/dev/null 2>&1; then
    echo "docker is required to run the tests" >&2
    exit 1
  fi

  docker build -t touchfish_agent_test "$ROOT_DIR" >/dev/null
  docker run --rm \
    --entrypoint /bin/bash \
    -e RUN_IN_CONTAINER=1 \
    -e TEST_REPORT="/work/tests/report.txt" \
    -e AGENT_NAME="test_agent" \
    -e GITHUB_TOKEN="test_token" \
    -e REPO_URL="https://example.com/repo.git" \
    -v "$ROOT_DIR":/work \
    -w /work \
    touchfish_agent_test \
    /work/tests/unit_test.sh
}

if [[ "${RUN_IN_CONTAINER:-}" != "1" ]]; then
  run_in_container
  exit $?
fi

PATH="$ROOT_DIR/tests/mocks:$PATH"

TEST_TMP=$(mktemp -d)
mkdir -p "$(dirname "$REPORT_PATH")"
: > "$REPORT_PATH"
exec > >(tee -a "$REPORT_PATH") 2>&1
export PS4='+ ${BASH_SOURCE##*/}:${LINENO}: '
set -x

cleanup() {
  rm -rf "$TEST_TMP"
}
trap cleanup EXIT

log_report() {
  echo "$*" | tee -a "$REPORT_PATH"
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  if [[ "$haystack" != *"$needle"* ]]; then
    echo "Expected to find: $needle" >&2
    return 1
  fi
}

setup_repo() {
  local repo="$1"
  local remote="$2"

  mkdir -p "$repo" "$remote"
  git init -q "$repo"
  git init -q --bare "$remote"
  git -C "$repo" config user.email "test@example.com"
  git -C "$repo" config user.name "Test"
  git -C "$repo" remote add origin "$remote"
}

run_test() {
  local name="$1"
  shift

  if "$@"; then
    log_report "PASS: $name"
  else
    log_report "FAIL: $name"
    return 1
  fi
}

case_issue_fix_multiple_comments() {
  local repo="$TEST_TMP/repo_issue"
  local remote="$TEST_TMP/remote_issue.git"
  setup_repo "$repo" "$remote"

  echo "base" > "$repo/file.txt"
  git -C "$repo" add file.txt
  git -C "$repo" commit -m "base" >/dev/null
  git -C "$repo" push -u origin HEAD >/dev/null

  local gh_log="$TEST_TMP/gh_issue.log"
  local codex_log="$TEST_TMP/codex_issue.log"

  export GH_CALL_LOG="$gh_log"
  export GH_MOCK_ISSUE_JSON="$ROOT_DIR/tests/data/issue_with_comments.json"
  export CODEX_PROMPT_LOG="$codex_log"
  export CODEX_OUTPUT_FILE="$repo/fix.txt"

  export AGENT_LIBRARY_MODE=1
  export AGENT_NAME="unit_agent"
  export GITHUB_TOKEN="dummy"
  export REPO_URL="file://$remote"
  export CODEX_CMD="codex"

  # shellcheck source=/dev/null
  source "$ROOT_DIR/scripts/agent.sh"

  issue_fix_cycle 42 101

  local last_msg
  last_msg=$(git -C "$repo" log -1 --pretty=%B)
  assert_contains "$last_msg" "Aaron: fix issue #42"

  local gh_calls
  gh_calls=$(cat "$gh_log")
  assert_contains "$gh_calls" "issue comment"

  local prompt
  prompt=$(cat "$codex_log")
  assert_contains "$prompt" "Fix incorrect prompt handling"
  assert_contains "$prompt" "First comment with extra context."
}

case_requirement_changes() {
  local repo="$TEST_TMP/repo_req"
  local remote="$TEST_TMP/remote_req.git"
  setup_repo "$repo" "$remote"

  cat <<'REQ' > "$repo/REQUIREMENTS.md"
# Requirements

Initial requirements.
REQ

  git -C "$repo" add REQUIREMENTS.md
  git -C "$repo" commit -m "base" >/dev/null
  git -C "$repo" push -u origin HEAD >/dev/null

  local last_sha
  last_sha=$(git -C "$repo" rev-parse HEAD)

  echo "Updated requirements." >> "$repo/REQUIREMENTS.md"

  local codex_log="$TEST_TMP/codex_req.log"
  export CODEX_PROMPT_LOG="$codex_log"
  export CODEX_OUTPUT_FILE="$repo/impl.txt"
  export CODEX_CMD="codex"

  export AGENT_LIBRARY_MODE=1
  export AGENT_NAME="unit_agent"
  export GITHUB_TOKEN="dummy"
  export REPO_URL="file://$remote"

  # shellcheck source=/dev/null
  source "$ROOT_DIR/scripts/agent.sh"

  implementing_cycle "$last_sha" "$repo/REQUIREMENTS.md"

  local last_msg
  last_msg=$(git -C "$repo" log -1 --pretty=%B)
  assert_contains "$last_msg" "Aaron: implement requirement updates"

  local prompt
  prompt=$(cat "$codex_log")
  assert_contains "$prompt" "Changed requirements diff:"
  assert_contains "$prompt" "+Updated requirements."
}

case_pr_merged() {
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
}

failures=0

run_test "Issue fix with multiple comments" case_issue_fix_multiple_comments || failures=$((failures+1))
run_test "Requirement changes" case_requirement_changes || failures=$((failures+1))
run_test "PR merged" case_pr_merged || failures=$((failures+1))

if [[ $failures -ne 0 ]]; then
  log_report "FAILED: $failures test(s) failed"
  exit 1
fi

log_report "SUCCESS: all tests passed"
