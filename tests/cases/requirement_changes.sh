TEST_NAME="Requirement changes"

INPUT_CHANGE_LINE="Updated requirements."
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
  export CODEX_PROMPT_LOG="$codex_log"
  export CODEX_OUTPUT_FILE="$repo/impl.txt"
  export CODEX_CMD="codex"

  export AGENT_LIBRARY_MODE=1
  export AGENT_NAME="unit_agent"
  export GITHUB_TOKEN="dummy"
  export REPO_URL="file://$remote"

  # shellcheck source=/dev/null
  source "$ROOT_DIR/scripts/agent.sh"

  (cd "$repo" && implementing_cycle "$last_sha" "$repo/REQUIREMENTS.md")

  local prompt
  prompt=$(cat "$codex_log")

  local diff_output
  diff_output=$(git -C "$repo" diff "$last_sha..HEAD" -- "$repo/REQUIREMENTS.md")

  local expected_prompt
  expected_prompt=$(
    cat <<EOF
You are an automated coding agent. Implement the latest requirements for this repository.

Changed requirements diff:
$diff_output

Current requirements files:

----- $repo/REQUIREMENTS.md -----
$(cat "$repo/REQUIREMENTS.md")
EOF
  )

  assert_equal "$prompt" "$expected_prompt"
}
