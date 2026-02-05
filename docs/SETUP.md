# TouchFish Agent Setup Guide

## Prerequisites

- Docker installed on the host machine
- GitHub repository with admin access
- Anthropic API key for Claude Code

---

## 1. Self-Hosted Runner Setup

GitHub Actions self-hosted runner is required for running agent containers with persistent storage.

### 1.1 Add Runner to Repository

1. Go to your repository on GitHub
2. Navigate to **Settings** → **Actions** → **Runners**
3. Click **New self-hosted runner**
4. Select your OS (Linux recommended)
5. Follow the instructions to download and configure the runner

### 1.2 Runner Commands

```bash
# Download (example for Linux x64)
mkdir actions-runner && cd actions-runner
curl -o actions-runner-linux-x64-2.311.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.311.0/actions-runner-linux-x64-2.311.0.tar.gz
tar xzf ./actions-runner-linux-x64-2.311.0.tar.gz

# Configure
./config.sh --url https://github.com/YOUR_USERNAME/touchfish_agent --token YOUR_TOKEN

# Run as service (recommended)
sudo ./svc.sh install
sudo ./svc.sh start
```

### 1.3 Runner Requirements

The runner host must have:
- Docker installed and accessible
- At least 4GB RAM
- Network access to GitHub and Anthropic API

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
| `ANTHROPIC_API_KEY` | Your Anthropic API key for Claude Code |

### 3.2 Claude Code Configuration

On the self-hosted runner, configure Claude Code:

```bash
# Create Claude config directory
mkdir -p ~/.claude

# Login to Claude Code (interactive)
claude login

# Or set API key directly
export ANTHROPIC_API_KEY=your_api_key_here
```

---

## 4. Test the Setup

### 4.1 Manual Container Test

```bash
# Test container startup
docker run --rm \
  -v $(pwd):/workspace \
  -e AGENT_NAME=DEV \
  -e GITHUB_TOKEN=test \
  -e COMMIT_MESSAGE="Test message" \
  -e BRANCH_NAME=test \
  -e REPO_NAME=test/repo \
  touchfish-agent:latest echo "Container works!"
```

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

### Runner Not Picking Up Jobs

```bash
# Check runner status
cd actions-runner
./svc.sh status

# View logs
journalctl -u actions.runner.YOUR_REPO.YOUR_RUNNER -f
```

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

2. Verify API key is set:
   ```bash
   echo $ANTHROPIC_API_KEY
   ```

### Permission Issues

```bash
# Ensure runner user can access Docker
sudo usermod -aG docker $USER
newgrp docker
```

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
*Last updated: 2026-02-05*
