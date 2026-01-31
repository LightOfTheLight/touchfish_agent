# Readme

## Goal

An AI workflow to leverage on Github eco-systems, so that:
- Use github as main user-agent interaction interface
    > - Markdown files for requirements
    > - Github issues for bugfixs / adjustment
    > - Branch / PR as session.
- Records every transaction as git commits
- Minimal dependencies
- For solo or tiny team with 2-3 members


## Resourse requirements

- A container host with physical storage for workspaces
- Containers for agent runtime
- Access to Github
- AI code agent(`codex`, `claude code`)

## Workflow

### Session start
1. User clone project to host workspaces folder.
1. Start agent containers in project folder, with set agent name.
1. Agent periodically scan for branch name matches `agent/<agent_name>/*`
1. Check out the first match, start the session

### Session process

1. Agent create PR to `master` once session started
1. User describe requirements by updating the requirements markdown files and commit
1. User create issues for agent implementation issues and defects that want to fix in this session. Label the issue with `Agent to fix`, and tag this branch name in description.

#### Session cycles

##### Issue fixing cycles
1. Agent scans the issues with `Agent to fix` label and current PR is mentioned in the description
1. Update label to `Agent fixing` for the first issue found.
1. Agent to fix this issue, commit with proper descriptions
1. Update the issue label to `Agent fixed to be verified`
1. End this cycle

#### implementation cycles
1. Agent watches the commits on this branch if no issues matches, and take the diff of requirements as requirements for this session
1. Agent implement the requirements, commit with proper descriptions

#### ending the cycle
1. Agent or github action triggers CI/CD
1. Agent updates the PR
1. Move to next cycle

### Session exits

1. User approve PR and delete the branch
1. Agent watch PR status, once merged connsider session closed.
1. Agent compact the session and back to branch scanning



