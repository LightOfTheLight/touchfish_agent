# Requirements

## Goal

A container compose to execute an AI workflow that leverage mainly on Github eco-systems.

Supports:
- github cli that can manage the project repo
- codex cli that does the workload
- project and codex session file stored on host system and mounted as volume

## Programing language

- As simple as possible, use shell script if possible
- If needed, can use python

## Highlevel requirement

### Inputs

- agent name
- github token
- repo url

### Main loop

- Main loop starts with the container
- Watch github repo branches, find branches that:
    * Name matches `agent/<agent name>/*`
    * Not merged to main/master
- If any matches found, check out the first match, enter the repo dir and create a PR to `master`/`main` (based on the repo setting) if the PR is not exists
- Start `Session loop`

### Session loop

1. Find github issues that:
    * Mentions current PR in the title
    * Labels `agent_to_fix`
1. If any issue found, execute `Issue fixing cycle` with the first issue found
1. If no issue found, look for changes in file:
    - REQUIREMENTS.md
    - CICD_REQUIREMENTS.md
    - Other files mentioned in above files
1. If any changes found, consider the difference as requirement change and execute `Implementing cycle`
1. If none of above found, pause a while and start this loop again

#### Exit criteria

1. Exit session loop when the PR is merged
1. Before exit, compact agent session
1. After exit, continue next main loop cycle

### Issue fixing cycle

1. Update current issue label to `agent_fixing`
1. Start agent (`codex cli` in this case) to fix the issue based on the description and subsequence comments
1. Commit with proper description and push commit
1. Add comment to this issue about this fix. Comment should start with: "<agent name>: ". This will be the indicator of agent generated comment. User will never comment with this prefix.
1. Update label to `agent_pending_verify`
1. Update PR

** Note: `agent_pending_verify` status might be changed back to `agent_to_fix` after verification failed. Agent must be able to comperhance the full conversation of this issue and fix accordingly.
** Note 2: Issue could be bug or agent implementation fault

### Implementing cycle

1. Feed the requirements files to agent for it to implement. Note that agent must be able to consider both the requirements and the difference of last commit. As it must understand whole requirement and the changes of requirements as well.
1. Commit with proper description and push commit
1. Update PR



## Documentation requirements

- `BUILD.md`: instructions of how to build the images
- `USAGE.md`: instructions of how to use this project, including how to get and set tokens of `codex` and `gh`

## Unit Test requirements

- Generate unit test script `tests/unit_test.sh`:
    * Mock `gh` command to emulate github output
    * Mock `codex` command to varify agent prompt
    * Create one-time containers to run the test script and generate report
    * Test cases should be data driven, test data should be easy to understand
    * Use mock values for required environment variables and avoid container entrypoint that expects real values
    * Print every command executed during unit tests for investigation
    * Provide a command-line flag to enable verbose unit test output (default off)
    * Mock `git` to avoid network push during unit tests
    * Provide a command-line flag to disable running tests in container (default on)
    * Each test case should be in a separate file with clear input/expected variables
    * Treat `gh`/`git` as mocked inputs; treat `codex` as blackbox and verify full input prompts exactly as generated
    * Test case for requirement changes must use mocked REQUIREMENTS content and mocked git diff output
    * Test case for merged PR must verify `/compact` prompt is sent to codex
    * Covers scenarios:
        - Issue fix with multiple comments
        - Requirement changes
        - PR merged
- Generate test readme file `tests/README.md` to explain how to run the tests
