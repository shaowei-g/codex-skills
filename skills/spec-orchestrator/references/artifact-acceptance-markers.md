# Artifact Acceptance Markers

YAML front matter markers are now optional metadata only.

## Current Rule

- The orchestrator no longer requires YAML front matter to accept a delegated run.
- Missing YAML headers must not fail delegated-run acceptance.
- Repositories may still keep front matter for their own local conventions.

## Practical Effect

- `spec.md`, `plan.md`, `tasks.md`, `implementation-status.md`, and `handoff.md` may be plain markdown files.
- Routing and acceptance rely on the delegated response status and current repository state, not on validated YAML headers.

## Backward Compatibility

Older markerized artifacts remain allowed, but the skill treats them as optional content rather than a required acceptance contract.
