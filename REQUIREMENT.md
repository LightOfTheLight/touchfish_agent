# Project Requirements

## 1. Overview

**Project Name:** TouchFish Agent
**Project Type:** AI-driven GitHub Workflow System
**Target Users:** Solo developers or small teams (2-3 members)

### 1.1 Vision
An automated AI workflow system that leverages the GitHub ecosystem to manage software development tasks through AI agents, using GitHub's native features as the primary interface.

### 1.2 Core Principles
- **GitHub-Native:** Use GitHub as the single source of truth and interaction interface
- **Transparency:** Record every transaction as git commits for full traceability
- **Simplicity:** Minimal dependencies for easy setup and maintenance
- **Collaboration:** Designed for small team workflows

---

## 2. Functional Requirements

### 2.1 User Interface (GitHub-Based)

| Interface Element | Purpose |
|------------------|---------|
| Markdown Files | Define and document requirements |
| GitHub Issues | Track bugfixes and adjustments |
| Branches/PRs | Represent working sessions |
| Commit Messages | Trigger agent actions and provide context |

### 2.2 Agent System

#### 2.2.1 Agent Types

| Agent | Responsibility |
|-------|----------------|
| **PO (Product Owner)** | Manage requirements, maintain project guidelines, translate user input from README.md into formal REQUIREMENT.md |
| **DEV (Developer)** | Implement features and fixes based on REQUIREMENT.md |
| **TESTER** | Create and maintain test cases based on REQUIREMENT.md |
| **(TBD) Agent 4** | Reserved for future definition |
| **(TBD) Agent 5** | Reserved for future definition |

#### 2.2.2 Agent Folder Structure
Each agent shall maintain a dedicated folder containing:
- Agent definition and responsibilities (`{AGENT_NAME}.md`)
- History and activity log (`history.md`)
- Any agent-specific configuration or templates

### 2.3 Workflow Requirements

#### 2.3.1 Session Start
1. User commits changes to README.md
2. Commit message specifies the target agent to invoke
3. GitHub Action triggers container startup
4. Container pulls latest code from repository
5. Claude Code initializes with specified agent context

#### 2.3.2 Session Process
1. Agent reads its folder to understand role and context
2. Agent reads commit message to understand the task
3. Agent performs work according to its responsibilities
4. Agent creates/updates PR with changes
5. All changes are committed with descriptive messages

#### 2.3.3 Session Exit
1. User reviews and approves PR
2. PR is merged, branch is deleted
3. Agent detects merged status
4. Agent compacts session data
5. System returns to branch scanning mode

---

## 3. Technical Requirements

### 3.1 Infrastructure

| Component | Requirement |
|-----------|-------------|
| Container Host | Must support persistent storage for workspaces |
| Runtime Containers | One per agent session |
| GitHub Access | Full repository access (read/write) |
| AI Engine | Claude Code agent |

### 3.2 GitHub Integration
- GitHub Actions for workflow automation
- Webhook support for real-time triggers
- PR API access for status monitoring
- Branch management capabilities

### 3.3 Container Requirements
- Ability to clone/pull repositories
- Claude Code CLI installed and configured
- Access to agent configuration folders
- Git credentials configured

---

## 4. Non-Functional Requirements

### 4.1 Reliability
- Sessions should be resumable after interruption
- All state should be persisted in git commits
- Failed sessions should not corrupt repository state

### 4.2 Traceability
- Every action must be recorded as a git commit
- Agent decisions should be documented in history.md
- PR descriptions should summarize session activities

### 4.3 Scalability
- Support concurrent sessions on different branches
- Agent containers should be stateless (state in git)

### 4.4 Security
- Minimal permissions required for agents
- No secrets stored in repository
- Container isolation between sessions

---

## 5. Acceptance Criteria

### 5.1 MVP (Minimum Viable Product)
- [ ] PO agent can read README.md and generate REQUIREMENT.md
- [ ] DEV agent can read REQUIREMENT.md and create implementation
- [ ] TESTER agent can read REQUIREMENT.md and create test cases
- [ ] GitHub Action triggers correct agent based on commit message
- [ ] All agent actions are recorded as git commits
- [ ] PR workflow completes successfully

### 5.2 Future Enhancements
- Define remaining 2 agent types
- Add agent collaboration workflows
- Implement session analytics
- Add rollback capabilities

---

## 6. Glossary

| Term | Definition |
|------|------------|
| Agent | An AI-powered automated worker with a specific role |
| Session | A complete workflow cycle from commit to PR merge |
| TouchFish | Project codename (colloquial for taking a break/relaxing) |

---

*Document maintained by: PO Agent*
*Last updated: 2026-02-05*
