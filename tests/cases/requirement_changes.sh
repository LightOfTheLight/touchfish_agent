TEST_NAME="Requirement changes"

INPUT_BASE_CONTENT=$'# Requirements\n\nInitial requirements.\n'
INPUT_UPDATED_CONTENT=$'# Requirements\n\nInitial requirements.\nUpdated requirements.\n'
INPUT_MOCK_DIFF=$'diff --git a/REQUIREMENTS.md b/REQUIREMENTS.md\nindex 1111111..2222222 100644\n--- a/REQUIREMENTS.md\n+++ b/REQUIREMENTS.md\n@@ -1,3 +1,4 @@\n # Requirements\n \n Initial requirements.\n+Updated requirements.\n'
run_case() {
  local repo="$TEST_TMP/repo_req"
  local remote="$TEST_TMP/remote_req.git"
  setup_repo "$repo" "$remote"

  printf '%s' "$INPUT_BASE_CONTENT" > "$repo/REQUIREMENTS.md"

  git -C "$repo" add REQUIREMENTS.md
  git -C "$repo" commit -m "base" >/dev/null
  git -C "$repo" push -u origin HEAD >/dev/null

  local last_sha
  last_sha=$(git -C "$repo" rev-parse HEAD)

  printf '%s' "$INPUT_UPDATED_CONTENT" > "$repo/REQUIREMENTS.md"

  local codex_log="$TEST_TMP/codex_req.log"
  export CODEX_PROMPT_LOG="$codex_log"
  export CODEX_OUTPUT_FILE="$repo/impl.txt"
  export CODEX_CMD="codex"
  export GIT_MOCK_DIFF="$INPUT_MOCK_DIFF"

  export AGENT_LIBRARY_MODE=1
  export AGENT_NAME="unit_agent"
  export GITHUB_TOKEN="dummy"
  export REPO_URL="file://$remote"

  # shellcheck source=/dev/null
  source "$ROOT_DIR/scripts/agent.sh"

  (cd "$repo" && implementing_cycle "$last_sha" "$repo/REQUIREMENTS.md")

  local prompt
  prompt=$(cat "$codex_log")

  local expected_prompt
  expected_prompt=$(
    cat <<EOF
You are an automated coding agent. Implement the latest requirements for this repository.

Changed requirements diff:
$INPUT_MOCK_DIFF

Current requirements files:

----- $repo/REQUIREMENTS.md -----
$INPUT_UPDATED_CONTENT
EOF
  )

  assert_equal "$prompt" "$expected_prompt"
}
