# Routing Snapshot Contract

Use this reference when `spec-orchestrator` needs a repo-local routing cache for one feature.

## Goal

Avoid repeating fresh inspection on every run when the current workflow state was already established by an authoritative delegated result and the feature artifacts have not changed.

A routing snapshot is a coordination cache. It is not formal phase acceptance by itself.

## Location

Default snapshot path:

- `.codex/spec-orchestrator-state/<feature>/routing-snapshot.json`

The snapshot must stay repo-local so the orchestrator can resume without rediscovering temp paths or relying on chat history.

## Reuse Rule

A routing snapshot is reusable only when all are true:

- the current feature fingerprint matches the snapshot fingerprint
- the snapshot points to a schema-valid delegated response
- when the snapshot basis is `validated_markers`, marker validation passed
- the feature slug in the snapshot matches the current feature target

If any of these fail, treat the snapshot as `missing`, `stale`, or `invalid` and fall back to normal inspection with `spec-viewer`.

## Authority Rule

The routing snapshot is never stronger than authoritative artifacts.

- validated artifact markers override a stale or conflicting snapshot
- the current schema-valid inspection result overrides non-authoritative summaries
- execution logs never justify route reuse by themselves

## Schema

```json
{
  "schema_version": 1,
  "snapshot_kind": "routing",
  "feature_slug": "001-example-feature",
  "created_at": "2026-03-23T02:07:09Z",
  "updated_at": "2026-03-23T02:07:09Z",
  "authoritative_basis": "validated_markers",
  "phase_just_validated": "specification",
  "current": {
    "feature_fingerprint": "sha256:...",
    "artifact_count": 3,
    "earliest_unresolved_phase": "planning",
    "recommended_next_phase": "planning",
    "recommended_next_subagent": "spec-planner"
  },
  "validation": {
    "response_file": "/abs/path/to/response.md",
    "response_sha256": "sha256:...",
    "response_schema_valid": true,
    "marker_validation_mode": "required",
    "marker_validation_passed": true,
    "validated_at": "2026-03-23T02:07:09Z",
    "validator": "skills/spec-orchestrator/scripts/validate_delegated_run.sh"
  },
  "artifacts": [
    {
      "path": "specs/001-example-feature/spec.md",
      "sha256": "..."
    }
  ]
}
```

## Allowed `authoritative_basis` values

- `validated_inspection`
- `validated_markers`

## Fingerprint Rule

The feature fingerprint should be derived from the sorted relative paths and content hashes of files under:

- `specs/<feature>/`

The orchestrator may reuse a snapshot only while that fingerprint still matches.

## Refresh Rule

Refresh the routing snapshot only after:

- a schema-valid inspection result is accepted, or
- a phase-owned update is accepted and required marker validation passed

Do not refresh the snapshot from terminal chatter or execution logs alone.
