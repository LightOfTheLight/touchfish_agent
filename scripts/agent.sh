#!/usr/bin/env bash
set -euo pipefail

log() {
  printf '[%s] %s\n' "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" "$*"
}

require_env() {
  local name
  for name in "$@"; do
    if [[ -z "${!name:-}" ]]; then
      log "Missing required env var: ${name}"
      exit 1
    fi
  done
}

ensure_gh_auth() {
  export GH_TOKEN="$GITHUB_TOKEN"
  if ! gh auth status >/dev/null 2>&1; then
    log "Authenticating gh via token"
    echo "$GITHUB_TOKEN" | gh auth login --with-token >/dev/null
  fi
  gh auth setup-git >/dev/null
}

ensure_git_identity() {
  local name="${AGENT_GIT_NAME:-${AGENT_NAME} bot}"
  local email="${AGENT_GIT_EMAIL:-${AGENT_NAME}@example.com}"

  git config user.name "$name"
  git config user.email "$email"
}

ensure_git_credentials() {
  if [[ "$REPO_URL" == https://* ]]; then
    local token_url
    token_url="${REPO_URL/https:\/\//https:\/\/${GITHUB_TOKEN}@}"
    git remote set-url origin "$token_url"
  fi
}

ensure_repo() {
  if [[ ! -d "$REPO_DIR/.git" ]]; then
    log "Cloning repo $REPO_URL"
    git clone "$REPO_URL" "$REPO_DIR"
  fi
}

get_default_branch() {
  gh repo view --json defaultBranchRef -q '.defaultBranchRef.name'
}

fetch_branch() {
  local branch="$1"
  git fetch origin "$branch" >/dev/null 2>&1 || true
}

find_agent_branch() {
  local base_branch="$1"
  local branch
  local candidate=""

  git fetch origin "$base_branch" >/dev/null 2>&1 || true

  while read -r branch; do
    [[ -z "$branch" ]] && continue
    fetch_branch "$branch"
    if git merge-base --is-ancestor "origin/$branch" "origin/$base_branch" >/dev/null 2>&1; then
      continue
    fi
    candidate="$branch"
    break
  done < <(git ls-remote --heads origin "agent/${AGENT_NAME}/*" | awk '{print $2}' | sed 's#refs/heads/##')

  echo "$candidate"
}

ensure_pr() {
  local branch="$1"
  local base_branch="$2"
  local pr_number

  pr_number=$(gh pr list --head "$branch" --base "$base_branch" --json number -q '.[0].number' || true)
  if [[ -n "$pr_number" ]]; then
    echo "$pr_number"
    return 0
  fi

  log "Creating PR for $branch -> $base_branch"
  gh pr create \
    --head "$branch" \
    --base "$base_branch" \
    --title "Agent ${AGENT_NAME} session: ${branch}" \
    --body "Automated session for ${branch}." >/dev/null

  pr_number=$(gh pr list --head "$branch" --base "$base_branch" --json number -q '.[0].number')
  echo "$pr_number"
}

pr_is_merged() {
  local pr_number="$1"
  gh pr view "$pr_number" --json merged -q '.merged'
}

state_file_for_branch() {
  local branch="$1"
  echo "$STATE_DIR/${branch//\//_}.state"
}

read_last_state() {
  local state_file="$1"
  if [[ -f "$state_file" ]]; then
    cat "$state_file"
  fi
}

write_state() {
  local state_file="$1"
  local sha="$2"
  echo "$sha" > "$state_file"
}

collect_requirement_files() {
  python3 /opt/agent/scripts/requirements_files.py "$REPO_DIR"
}

requirements_changed() {
  local last_sha="$1"
  shift
  local files=("$@")

  if [[ -z "$last_sha" ]]; then
    return 1
  fi

  if [[ ${#files[@]} -eq 0 ]]; then
    return 1
  fi

  if git diff --name-only "$last_sha..HEAD" -- "${files[@]}" | grep -q .; then
    return 0
  fi
  return 1
}

run_codex_with_prompt() {
  local prompt_file="$1"

  if ! command -v "$CODEX_CMD" >/dev/null 2>&1; then
    log "codex command not found: $CODEX_CMD"
    return 1
  fi

  log "Running codex"
  "$CODEX_CMD" < "$prompt_file"
}

issue_fix_cycle() {
  local issue_number="$1"
  local pr_number="$2"

  log "Fixing issue #$issue_number"
  gh issue edit "$issue_number" --add-label agent_fixing --remove-label agent_to_fix >/dev/null 2>&1 || true

  local prompt_file
  prompt_file=$(mktemp)

  gh issue view "$issue_number" --json title,body,comments > "$prompt_file.json"
  python3 - <<'PY' "$prompt_file" "$prompt_file.json"
import json
import sys

prompt_path = sys.argv[1]
json_path = sys.argv[2]

with open(json_path, "r", encoding="utf-8") as fh:
    data = json.load(fh)

lines = []
lines.append("You are an automated coding agent. Fix the issue below in this repository.")
lines.append("")
lines.append(f"Issue: {data.get('title','')}")
lines.append("")
lines.append(data.get("body") or "")
lines.append("")
lines.append("Comments:")
for comment in data.get("comments", []):
    lines.append(f"- {comment.get('author',{}).get('login','unknown')}: {comment.get('body','').strip()}")

with open(prompt_path, "w", encoding="utf-8") as out:
    out.write("\n".join(lines))
PY

  if run_codex_with_prompt "$prompt_file"; then
    if git status --porcelain | grep -q .; then
      git add -A
      git commit -m "Aaron: fix issue #$issue_number"
      git push origin HEAD
      local sha
      sha=$(git rev-parse --short HEAD)
      gh issue comment "$issue_number" --body "${AGENT_NAME}: implemented fix in commit ${sha}." >/dev/null
      gh issue edit "$issue_number" --add-label agent_pending_verify --remove-label agent_fixing >/dev/null 2>&1 || true
      gh pr comment "$pr_number" --body "Agent ${AGENT_NAME} updated: fixed issue #${issue_number}." >/dev/null 2>&1 || true
    else
      log "No changes detected after codex run"
    fi
  else
    log "codex failed or unavailable for issue #$issue_number"
  fi

  rm -f "$prompt_file" "$prompt_file.json"
}

implementing_cycle() {
  local last_sha="$1"
  shift
  local files=("$@")

  log "Implementing requirement updates"

  local prompt_file
  prompt_file=$(mktemp)

  {
    echo "You are an automated coding agent. Implement the latest requirements for this repository."
    echo
    echo "Changed requirements diff:"
    if [[ -n "$last_sha" ]]; then
      git diff "$last_sha..HEAD" -- "${files[@]}"
    else
      echo "(no previous state recorded)"
    fi
    echo
    echo "Current requirements files:"
    for file in "${files[@]}"; do
      echo
      echo "----- $file -----"
      cat "$file"
    done
  } > "$prompt_file"

  if run_codex_with_prompt "$prompt_file"; then
    if git status --porcelain | grep -q .; then
      git add -A
      git commit -m "Aaron: implement requirement updates"
      git push origin HEAD
    else
      log "No changes detected after codex run"
    fi
  else
    log "codex failed or unavailable for implementing cycle"
  fi

  rm -f "$prompt_file"
}

session_loop() {
  local pr_number="$1"
  local branch="$2"
  local base_branch="$3"

  local state_file
  state_file=$(state_file_for_branch "$branch")

  while true; do
    if [[ "$(pr_is_merged "$pr_number")" == "true" ]]; then
      log "PR #$pr_number merged, ending session"
      compact_session
      break
    fi

    local issue_number
    issue_number=$(gh issue list --label agent_to_fix --search "\"#${pr_number}\" in:title" --json number -q '.[0].number' || true)

    if [[ -n "$issue_number" ]]; then
      issue_fix_cycle "$issue_number" "$pr_number"
      sleep "$POLL_INTERVAL"
      continue
    fi

    mapfile -t req_files < <(collect_requirement_files)

    local last_sha
    last_sha=$(read_last_state "$state_file")

    if [[ -z "$last_sha" ]]; then
      last_sha=$(git rev-parse HEAD)
      write_state "$state_file" "$last_sha"
      sleep "$POLL_INTERVAL"
      continue
    fi

    if requirements_changed "$last_sha" "${req_files[@]}"; then
      implementing_cycle "$last_sha" "${req_files[@]}"
      local new_sha
      new_sha=$(git rev-parse HEAD)
      write_state "$state_file" "$new_sha"
      sleep "$POLL_INTERVAL"
      continue
    fi

    sleep "$POLL_INTERVAL"
  done
}

compact_session() {
  if [[ -n "${CODEX_COMPACT_CMD:-}" ]]; then
    log "Compacting codex session"
    $CODEX_COMPACT_CMD
  else
    log "Compact session requested; no compaction command configured"
  fi
}

main_loop() {
  while true; do
    ensure_repo
    cd "$REPO_DIR"

    ensure_git_identity
    ensure_git_credentials

    git fetch origin >/dev/null 2>&1 || true

    local base_branch
    base_branch=$(get_default_branch)

    local agent_branch
    agent_branch=$(find_agent_branch "$base_branch")

    if [[ -z "$agent_branch" ]]; then
      log "No matching agent branches found"
      sleep "$POLL_INTERVAL"
      continue
    fi

    log "Using agent branch $agent_branch"
    git checkout -B "$agent_branch" "origin/$agent_branch" >/dev/null 2>&1

    local pr_number
    pr_number=$(ensure_pr "$agent_branch" "$base_branch")

    session_loop "$pr_number" "$agent_branch" "$base_branch"
  done
}

if [[ "${AGENT_LIBRARY_MODE:-}" != "1" ]]; then
  require_env AGENT_NAME GITHUB_TOKEN REPO_URL

  WORKDIR=${WORKDIR:-/workspace}
  REPO_DIR=${REPO_DIR:-$WORKDIR/repo}
  STATE_DIR=${STATE_DIR:-$WORKDIR/.agent_state}
  POLL_INTERVAL=${POLL_INTERVAL:-60}
  CODEX_CMD=${CODEX_CMD:-codex}
  CODEX_SESSION_FILE=${CODEX_SESSION_FILE:-/codex/session.json}

  mkdir -p "$WORKDIR" "$STATE_DIR"

  ensure_gh_auth
  main_loop
fi
