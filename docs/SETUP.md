# TouchFish Agent Setup Guide

## Prerequisites

- GitHub repository with admin access
- Claude Pro subscription (for OAuth token) or Anthropic API key

---

## 1. Runner Setup

The TouchFish Agent system uses **GitHub-hosted cloud runners** (`ubuntu-latest`). No self-hosted runner is required.

The workflow automatically:
1. Builds the Docker container on the cloud runner
2. Runs the agent container with your repository mounted
3. Pushes changes and creates a PR

---

## 2. Build Agent Container

```bash
# Navigate to project directory
cd touchfish_agent

# Build the Docker image
docker build -t touchfish-agent:latest .

# Verify the image
docker images | grep touchfish-agent
```

---

## 3. Configure Secrets

### 3.1 GitHub Repository Secrets

Go to **Settings** → **Secrets and variables** → **Actions** and add:

| Secret Name | Description |
|-------------|-------------|
| `CLAUDE_CODE_OAUTH_TOKEN` | OAuth token from Claude Pro subscription (recommended) |
| `ANTHROPIC_API_KEY` | Anthropic API key (alternative to OAuth token) |

You only need one of the above secrets. `CLAUDE_CODE_OAUTH_TOKEN` is recommended for Claude Pro subscribers.

### 3.2 Getting Your OAuth Token

For Claude Pro subscribers:

```bash
# Login to Claude Code locally
claude login

# Find your OAuth token
cat ~/.claude/.credentials.json
# Copy the oauth_token value
```

---

## 4. Test the Setup

### 4.1 Manual Container Test

```bash
# Test container startup
docker run --rm \
  --user "$(id -u):$(id -g)" \
  -v $(pwd):/workspace \
  -v /tmp/agent-home:/home/agent \
  -e HOME=/home/agent \
  -e AGENT_NAME=DEV \
  -e GITHUB_TOKEN=test \
  -e CLAUDE_CODE_OAUTH_TOKEN=your_token_here \
  -e COMMIT_MESSAGE="Test message" \
  -e BRANCH_NAME=test \
  -e REPO_NAME=test/repo \
  touchfish-agent:latest echo "Container works!"
```

> **Note:** The `--user` flag and `-v /tmp/agent-home:/home/agent` are required so the container runs as your host user and can write to the mounted workspace volume.

### 4.2 Workflow Test

1. Create a new branch:
   ```bash
   git checkout -b test/agent-trigger
   ```

2. Make a commit with agent trigger:
   ```bash
   echo "test" >> test.txt
   git add test.txt
   git commit -m "@DEV Test agent trigger"
   git push origin test/agent-trigger
   ```

3. Check GitHub Actions tab for workflow execution

---

## 5. Usage

### Triggering Agents

Include agent name in your commit message:

| Trigger | Agent | Purpose |
|---------|-------|---------|
| `@PO` or `[PO]` | Product Owner | Requirements management |
| `@DEV` or `[DEV]` | Developer | Implementation |
| `@TESTER` or `[TESTER]` | Tester | Test creation |

### Example Workflows

**Updating requirements:**
```bash
# Edit README.md with new requirements
git add README.md
git commit -m "@PO Please update requirements based on new features"
git push
```

**Implementing a feature:**
```bash
git checkout -b feature/user-auth
git commit --allow-empty -m "@DEV Implement user authentication per REQUIREMENT.md section 2.1"
git push origin feature/user-auth
```

**Creating tests:**
```bash
git commit --allow-empty -m "@TESTER Create test cases for user authentication"
git push
```

---

## 6. Troubleshooting

### Container Build Fails

```bash
# Check Docker daemon
docker info

# Build with verbose output
docker build --progress=plain -t touchfish-agent:latest .
```

### Agent Not Responding

1. Check Claude Code authentication:
   ```bash
   claude --version
   claude auth status
   ```

2. Verify OAuth token or API key is set in GitHub Secrets

3. Check GitHub Actions workflow logs for error details

### Permission Issues

If the agent cannot write to the workspace, ensure the `run-agent` job passes `--user "$(id -u):$(id -g)"` to the docker run command. This is already configured in the workflow.

---

## 7. Architecture Reference

```
┌─────────────────────────────────────────────────────────┐
│                      GitHub                              │
│  ┌──────────┐    ┌──────────┐    ┌──────────────────┐  │
│  │  Branch  │───→│  Action  │───→│  Self-hosted     │  │
│  │  Push    │    │  Trigger │    │  Runner          │  │
│  └──────────┘    └──────────┘    └────────┬─────────┘  │
└───────────────────────────────────────────┼─────────────┘
                                            │
                    ┌───────────────────────▼───────────────┐
                    │         Container Host                 │
                    │  ┌─────────────────────────────────┐  │
                    │  │     touchfish-agent:latest      │  │
                    │  │  ┌───────────────────────────┐  │  │
                    │  │  │      Claude Code CLI      │  │  │
                    │  │  │  ┌─────────────────────┐  │  │  │
                    │  │  │  │   Agent Context     │  │  │  │
                    │  │  │  │   (PO/DEV/TESTER)   │  │  │  │
                    │  │  │  └─────────────────────┘  │  │  │
                    │  │  └───────────────────────────┘  │  │
                    │  └─────────────────────────────────┘  │
                    │              │                         │
                    │              ▼                         │
                    │  ┌─────────────────────────────────┐  │
                    │  │   /workspace (repo mount)       │  │
                    │  │   - agents/                     │  │
                    │  │   - REQUIREMENT.md              │  │
                    │  │   - README.md                   │  │
                    │  └─────────────────────────────────┘  │
                    └───────────────────────────────────────┘
```

---

*Document maintained by: DEV Agent*
*Last updated: 2026-02-28*
