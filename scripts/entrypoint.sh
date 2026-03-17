#!/bin/bash
# TouchFish Agent Entrypoint Script
# Initializes agent session with Claude Code CLI

set -e

# Color output helpers
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Validate required environment variables
validate_env() {
    local required_vars=("AGENT_NAME" "GITHUB_TOKEN" "COMMIT_MESSAGE" "BRANCH_NAME")

    for var in "${required_vars[@]}"; do
        if [[ -z "${!var}" ]]; then
            log_error "Required environment variable $var is not set"
            exit 1
        fi
    done

    # Validate agent name
    if [[ ! "$AGENT_NAME" =~ ^(PO|DEV|TESTER)$ ]]; then
        log_error "Invalid agent name: $AGENT_NAME. Must be PO, DEV, or TESTER"
        exit 1
    fi

    # Check for authentication (OAuth token or API key)
    if [[ -z "$CLAUDE_CODE_OAUTH_TOKEN" ]] && [[ -z "$ANTHROPIC_API_KEY" ]]; then
        log_warn "Neither CLAUDE_CODE_OAUTH_TOKEN nor ANTHROPIC_API_KEY is set"
        log_warn "Claude Code may fail to authenticate"
    fi
}

# Configure git for the session
configure_git() {
    log_info "Configuring git..."
    git config --global user.name "TouchFish $AGENT_NAME Agent"
    git config --global user.email "agent-$AGENT_NAME@touchfish.local"
    git config --global --add safe.directory /workspace

    # Configure credential helper for GitHub
    git config --global credential.helper store
    echo "https://x-access-token:${GITHUB_TOKEN}@github.com" > "$HOME/.git-credentials"
}

# Build the agent prompt based on agent type
build_agent_prompt() {
    local agent_folder="/workspace/agents/$AGENT_NAME"
    local agent_def="$agent_folder/$AGENT_NAME.md"
    local agent_history="$agent_folder/history.md"

    if [[ ! -f "$agent_def" ]]; then
        log_error "Agent definition file not found: $agent_def"
        exit 1
    fi

    # Build the initialization prompt
    cat << EOF
As experienced $AGENT_NAME, understand the requirement from REQUIREMENT.md, start implementation, document your thinking process under /agents/$AGENT_NAME/history.md, document your role and responsibilities under /agents/$AGENT_NAME/$AGENT_NAME.md

## Context

**Branch:** $BRANCH_NAME
**Commit Message:** $COMMIT_MESSAGE
**Agent Type:** $AGENT_NAME

## Task

Read the commit message above to understand your task. Follow your role definition in agents/$AGENT_NAME/$AGENT_NAME.md and document your work in agents/$AGENT_NAME/history.md.

When complete:
1. Commit your changes with descriptive messages
2. Update your history.md with session notes
$(if [[ "$AGENT_NAME" == "PO" ]]; then
cat << 'PO_EOF'
3. IMPORTANT: Your final commit message MUST end with "@DEV" to hand off to the DEV agent for implementation.
   Example: "Requirements finalized for initial Chrome extension @DEV"
   This triggers the automated pipeline to continue with development.
PO_EOF
elif [[ "$AGENT_NAME" == "DEV" ]]; then
cat << 'DEV_EOF'
3. IMPORTANT: Your final commit message MUST end with "@TESTER" to hand off to the TESTER agent for validation.
   Example: "Implement bookmark management and popup UI @TESTER"
   This triggers the automated pipeline to continue with testing.
DEV_EOF
elif [[ "$AGENT_NAME" == "TESTER" ]]; then
cat << 'TESTER_EOF'
3. IMPORTANT: Write a `.agent-test-result` file in the repository root with your verdict:
   - If all tests pass: write "PASS" followed by a summary
   - If bugs found for DEV to fix: write "FAIL @DEV" followed by issue details
   - If requirements need PO clarification: write "FAIL @PO" followed by what needs clarifying
   This file controls the automated pipeline - it MUST be created before your session ends.
4. Your final commit message must reflect the verdict:
   - If PASS: use a normal descriptive message (pipeline will create a PR)
   - If FAIL @DEV: end the commit message with "@DEV" to re-trigger development
   - If FAIL @PO: end the commit message with "@PO" to re-trigger requirements
TESTER_EOF
fi)
EOF
}

# Run Claude Code with agent context
run_agent() {
    log_info "Starting $AGENT_NAME agent session..."
    log_info "Branch: $BRANCH_NAME"
    log_info "Task: $COMMIT_MESSAGE"

    local prompt
    prompt=$(build_agent_prompt)

    # Run Claude Code with the agent prompt
    # The -p flag runs in non-interactive mode
    # The --dangerously-skip-permissions flag is needed for automated execution
    cd /workspace

    # Run with timeout (30 minutes max) and max turns limit
    timeout 1800 claude -p --dangerously-skip-permissions --max-turns 50 "$prompt"
}

# Main execution
main() {
    log_info "TouchFish Agent Container Starting"
    log_info "=================================="

    validate_env
    configure_git

    log_info "Agent: $AGENT_NAME"
    log_info "Repository: $REPO_NAME"
    log_info "Branch: $BRANCH_NAME"
    log_info "=================================="

    run_agent

    log_info "=================================="
    log_info "Agent session completed"
}

main "$@"
