# Artifact Acceptance Markers

This reference defines explicit acceptance markers for workflow artifacts so `spec-orchestrator` and the specialist skills can distinguish **artifact existence** from **formal phase acceptance**.

Use these markers to make continuation, resume, and review decisions depend on durable repository state rather than chat summaries alone.

## Marker Location

For markerized phase artifacts, place a YAML front matter block at the top of the markdown file.

Example shell:

```yaml
---
phase: specification
status: ready
gate: pending
approved_by_orchestrator: false
last_gate_check: null
---
```

## Common Fields

Every markerized artifact must use these common fields:

- `phase`: the owning workflow phase for the artifact
- `status`: one of `draft`, `ready`, `accepted`, `superseded`
- `gate`: one of `pending`, `passed`, `failed`
- `approved_by_orchestrator`: `true` only when the orchestrator has formally accepted the artifact
- `last_gate_check`: ISO-8601 timestamp or `null`

## Acceptance Meaning

Treat an artifact as **formally accepted** only when all of the following are true:

- `status: accepted`
- `gate: passed`
- `approved_by_orchestrator: true`
- `last_gate_check` is populated

Do not infer acceptance from file existence alone.

## Validation

Validate markerized workflow artifacts with:

- `bash ./scripts/validate_artifact_markers.sh specs/<feature>`

Use:

- default mode for compatibility checks in repositories that may still contain unmarkerized artifacts
- `--require-markers` when a phase-owned update is expected to create or preserve markerized artifacts and missing front matter should fail the acceptance check

Examples:

```bash
bash ./scripts/validate_artifact_markers.sh specs/payment-refund
bash ./scripts/validate_artifact_markers.sh --require-markers specs/payment-refund
```

## Authority Rules

### Specialist authority

Specialists may:

- create the phase-owned artifact body
- preserve or initialize the marker block
- set `status` to `draft` or `ready`
- leave `gate` as `pending` when formal acceptance has not occurred yet
- update phase-local fields truthfully when they are part of the assigned artifact contract

Specialists must not:

- set `status: accepted`
- set `gate: passed` as a claim of formal phase acceptance
- set `approved_by_orchestrator: true`
- backdate `last_gate_check`

### Orchestrator authority

The orchestrator owns formal acceptance.

After validating a delegated result and confirming the phase gate passed, the orchestrator may promote an artifact to:

- `status: accepted`
- `gate: passed`
- `approved_by_orchestrator: true`
- `last_gate_check: <timestamp>`

If an accepted artifact is later replaced or invalidated, the orchestrator may downgrade or supersede it.

## Artifact-Specific Contracts

### `spec.md`

Required marker fields:

- `phase: specification`
- common fields from this reference

Optional phase-local fields:

- `ready_for_next_phase: planning`

A formally accepted `spec.md` means the feature scope, constraints, and acceptance criteria are specific enough to support planning.

### `plan.md`

Required marker fields:

- `phase: planning`
- common fields from this reference
- `execution_ready`: `true` or `false`

Interpretation:

- `execution_ready: true` means the plan is mature enough to support task decomposition or bounded implementation
- `execution_ready: false` means the artifact may still be informative, but it is not yet execution-ready

A formally accepted `plan.md` should normally have `execution_ready: true`.

### `tasks.md`

Required marker fields:

- `phase: task-decomposition`
- common fields from this reference
- `tasking_gate`: one of `pending`, `passed`, `failed`

Optional phase-local fields:

- `task_count`: integer

A formally accepted `tasks.md` should normally have `tasking_gate: passed`.

### `implementation-status.md`

Canonical path:

- `specs/<feature>/implementation-status.md`

Required marker fields:

- `phase: implementation`
- common fields from this reference
- `completed_task_ids`: list of task IDs completed in this bounded batch or recorded implementation pass
- `verification_commands`: list of verification commands or command groups used for the claimed completion state

Optional phase-local fields:

- `batch_id`: repository-local batch label

A formally accepted implementation record should describe only completed work that actually occurred and should list the concrete verification command set for that completed batch.

## Continuation and Review Interpretation

When resuming or reviewing one feature, use this order:

1. inspect markerized artifacts and their front matter
2. check whether the artifact is formally accepted
3. check whether the artifact body matches the claimed marker state
4. check cross-artifact consistency before routing forward

Recommended review labels:

- `accepted`
- `ready-but-unaccepted`
- `draft`
- `missing`
- `inconsistent`
- `superseded`

## Cross-Artifact Consistency Rules

Do not route forward just because a later file exists.

Apply these consistency checks:

- an accepted `plan.md` should not outrun an unaccepted `spec.md`
- an accepted `tasks.md` should not outrun an unaccepted or non-`execution_ready` `plan.md`
- an accepted `implementation-status.md` should not outrun an unaccepted `tasks.md`

If marker state and artifact content disagree, treat the artifact as inconsistent and route to the earliest unresolved phase.

## Backward Compatibility

Older repositories may not yet have markerized artifacts.

When markers are absent:

- do not assume formal acceptance from file existence alone
- allow `spec-viewer` or the orchestrator to inspect content and infer a provisional route
- prefer writing markerized artifacts on the next safe phase-owned update

## Related References

- orchestrator shell: `../SKILL.md`
- specialist execution boundary: `./specialist-execution-contract.md`
- specialist status meanings: `./specialist-status-semantics.md`
