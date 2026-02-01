TEST_NAME="Issue fix with multiple comments"

INPUT_ISSUE_NUMBER=42
INPUT_PR_NUMBER=101
EXPECTED_COMMIT_MESSAGE="Aaron: fix issue #42"
EXPECTED_PROMPT_TITLE="Fix incorrect prompt handling"
EXPECTED_PROMPT_COMMENT="First comment with extra context."
EXPECTED_GH_CALL="issue comment"
EXPECTED_GIT_CALL="git commit -m Aaron: fix issue #42"

run_case() {
  local repo="$TEST_TMP/repo_issue"
  local remote="$TEST_TMP/remote_issue.git"
  setup_repo "$repo" "$remote"

  echo "base" > "$repo/file.txt"
  git -C "$repo" add file.txt
  git -C "$repo" commit -m "base" >/dev/null
  git -C "$repo" push -u origin HEAD >/dev/null

  local gh_log="$TEST_TMP/gh_issue.log"
  local git_log="$TEST_TMP/git_issue.log"
  local codex_log="$TEST_TMP/codex_issue.log"

  export GH_CALL_LOG="$gh_log"
  export GIT_CALL_LOG="$git_log"
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

  (cd "$repo" && issue_fix_cycle "$INPUT_ISSUE_NUMBER" "$INPUT_PR_NUMBER")

  local last_msg
  last_msg=$(git -C "$repo" log -1 --pretty=%B)
  assert_contains "$last_msg" "$EXPECTED_COMMIT_MESSAGE"

  local gh_calls
  gh_calls=$(cat "$gh_log")
  assert_contains "$gh_calls" "$EXPECTED_GH_CALL"

  local git_calls
  git_calls=$(cat "$git_log")
  assert_contains "$git_calls" "$EXPECTED_GIT_CALL"

  local prompt
  prompt=$(cat "$codex_log")
  assert_contains "$prompt" "$EXPECTED_PROMPT_TITLE"
  assert_contains "$prompt" "$EXPECTED_PROMPT_COMMENT"
}
