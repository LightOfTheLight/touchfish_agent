# TouchFish Agent Container
# Runtime environment for AI agents with Claude Code CLI

FROM node:20-slim

LABEL maintainer="TouchFish Agent System"
LABEL description="Runtime container for TouchFish AI agents"

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    jq \
    ca-certificates \
    gnupg \
    && rm -rf /var/lib/apt/lists/*

# Install Claude Code CLI
RUN npm install -g @anthropic-ai/claude-code

# Create workspace directory
WORKDIR /workspace

# Copy entrypoint script
COPY scripts/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Environment variables (to be overridden at runtime)
ENV AGENT_NAME=""
ENV GITHUB_TOKEN=""
ENV CLAUDE_CODE_OAUTH_TOKEN=""
ENV COMMIT_SHA=""
ENV COMMIT_MESSAGE=""
ENV BRANCH_NAME=""
ENV REPO_NAME=""

# Default entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
