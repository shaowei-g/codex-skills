# Specialist Execution Contract

This reference defines the shared execution boundary for all specialists.

## Core Rules

- Complete at most one bounded specialist pass.
- Stay inside the assigned phase intent.
- Do not take routing authority away from the orchestrator.
- Return only the shared status-only schema in `./subagent-response-format.md`.

## Response Rule

Use exactly:

- `Status:`
- one bullet with `completed`, `blocked`, or `rejected`

No other response headings are required.

## Artifact Rule

- YAML front matter is not required.
- Do not depend on YAML header validation for acceptance.
- Phase-owned artifact content may still be created or updated when the assignment calls for it.
