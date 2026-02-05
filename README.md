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
- AI code agent(`claude code`)

## Agent requirements

- There shall be one agent folder which documents down agent behavior, comments and historys
- There shall be 5 agent types: 
    > - PO: who will be responsible for requierment and overall project guideline. It will read and understand the basic requirement from README.md from user input and generate project level requirement to REQUIREMENT.md
    > - DEV: who will be responsible for the actual implementation based on REQUIREMENT.md
    > - TESTER: who will be responsible for the test cases based on REQUIREMENT.md

## Workflow

### Session start
1. User commit requirement in README.md. the commit message will contain the next agent
1. The github action will be triggered to start the containers in project folder with mentioned agent name 
1. The container shall first pull the latest code based on the github action.
1. The container shall start one claude code based on agent name, init the session with agent folder with agent name

### Session process
1. Agent shall read through the agent folder to understand its role
1. Agent shall read the commit message to understand the changes
1. Agent shall update the project folder based on its role and given new task in the commit
1. Agent shall update the PR to with necessary changes.

### Session exits

1. User approve PR and delete the branch
1. Agent watch PR status, once merged connsider session closed.
1. Agent compact the session and back to branch scanning



