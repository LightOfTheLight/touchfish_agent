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

# Create non-root user (Claude Code refuses --dangerously-skip-permissions as root)
RUN useradd -m -s /bin/bash agent

# Create workspace directory
WORKDIR /workspace
RUN chown agent:agent /workspace

# Copy entrypoint script
COPY scripts/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Switch to non-root user
USER agent

# Environment variables (to be overridden at runtime)
ENV AGENT_NAME=""
ENV GITHUB_TOKEN=""
ENV COMMIT_SHA=""
ENV COMMIT_MESSAGE=""
ENV BRANCH_NAME=""
ENV REPO_NAME=""

# Default entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
