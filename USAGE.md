# Usage

## 1) Prepare environment variables

Copy the example file and edit values:

```bash
cp .env.example .env
```

Set the required values in `.env`:

- `AGENT_NAME`: the agent name used in branch matching (`agent/<agent name>/*`).
- `GITHUB_TOKEN`: a GitHub personal access token with repo access.
- `REPO_URL`: the HTTPS or SSH URL of the repo to work on.
- `WORKSPACE_DIR`: absolute path on the host where the repo will be cloned.
- `CODEX_SESSION_FILE`: absolute path on the host for the codex session file.

Optional values:

- `POLL_INTERVAL`: seconds between checks (default: 60).
- `CODEX_CMD`: codex CLI command inside the container (default: `codex`).
- `CODEX_API_KEY` / `OPENAI_API_KEY`: set the environment variable required by your codex CLI.

## 2) Create tokens

### GitHub token

1. Go to GitHub Settings → Developer settings → Personal access tokens.
2. Create a token with access to the target repo.
3. Paste it into `.env` as `GITHUB_TOKEN`.

### Codex token

1. Create an API token from your codex provider account.
2. Set the environment variable expected by your codex CLI in `.env`.
   - Use `CODEX_API_KEY` or `OPENAI_API_KEY` if your CLI expects one of those names.

## 3) Start the agent

```bash
docker compose up --build
```

The container will:

- Scan for branches named `agent/<AGENT_NAME>/*` that are not merged into the default branch.
- Create a PR to the default branch if missing.
- Enter the session loop to handle issues and requirement changes.

## 4) Stop the agent

```bash
docker compose down
```
