# Responsibility Map

This bundle uses a simplified contract.

## Orchestrator

The orchestrator owns:

- feature identification
- routing
- delegated-run acceptance
- snapshot refresh
- stop conditions

## Specialists

Specialists own:

- one bounded phase-local pass
- truthful `Status` response
- phase-owned file updates when the assigned phase requires them

## Shared Contracts

### `references/subagent-response-format.md`

Canonical shared response schema. The response now contains only:

- `Status`

### `references/artifact-acceptance-markers.md`

Historical marker reference. YAML front matter is optional and no longer validated as an acceptance gate.

### `scripts/validate_subagent_response.sh`

Shared validator for the status-only schema.

### `scripts/validate_delegated_run.sh`

Single delegated acceptance entry point. Accepts schema-valid delegated results without YAML header checks.
