TEST_NAME="Requirement changes"

INPUT_CHANGE_LINE="Updated requirements."
EXPECTED_COMMIT_MESSAGE="Aaron: implement requirement updates"
EXPECTED_PROMPT_DIFF="+Updated requirements."

run_case() {
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

  echo "$INPUT_CHANGE_LINE" >> "$repo/REQUIREMENTS.md"

  local codex_log="$TEST_TMP/codex_req.log"
  local git_log="$TEST_TMP/git_req.log"
  export CODEX_PROMPT_LOG="$codex_log"
  export CODEX_OUTPUT_FILE="$repo/impl.txt"
  export CODEX_CMD="codex"
  export GIT_CALL_LOG="$git_log"

  export AGENT_LIBRARY_MODE=1
  export AGENT_NAME="unit_agent"
  export GITHUB_TOKEN="dummy"
  export REPO_URL="file://$remote"

  # shellcheck source=/dev/null
  source "$ROOT_DIR/scripts/agent.sh"

  (cd "$repo" && implementing_cycle "$last_sha" "$repo/REQUIREMENTS.md")

  local last_msg
  last_msg=$(git -C "$repo" log -1 --pretty=%B)
  assert_contains "$last_msg" "$EXPECTED_COMMIT_MESSAGE"

  local prompt
  prompt=$(cat "$codex_log")
  assert_contains "$prompt" "Changed requirements diff:"
  assert_contains "$prompt" "$EXPECTED_PROMPT_DIFF"

  local git_calls
  git_calls=$(cat "$git_log")
  assert_contains "$git_calls" "$EXPECTED_COMMIT_MESSAGE"
}
