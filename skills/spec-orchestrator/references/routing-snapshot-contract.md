# Routing Snapshot Contract

Use this reference when `spec-orchestrator` needs a repo-local routing cache for one feature.

## Goal

Avoid repeating fresh inspection on every run when the current workflow state was already established by an authoritative delegated result and the feature artifacts have not changed.

A routing snapshot is a coordination cache. It is not formal phase acceptance by itself.

## Location

Default snapshot path:

- `.codex/spec-orchestrator-state/<feature>/routing-snapshot.json`

## Reuse Rule

A routing snapshot is reusable only when all are true:

- the current feature fingerprint matches the snapshot fingerprint
- the snapshot points to a schema-valid delegated response
- the feature slug in the snapshot matches the current feature target

If any of these fail, treat the snapshot as `missing`, `stale`, or `invalid` and fall back to normal inspection with `spec-viewer`.

## Authority Rule

The routing snapshot is never stronger than current repository state or the latest schema-valid delegated result.

## Schema

```json
{
  "schema_version": 1,
  "snapshot_kind": "routing",
  "feature_slug": "001-example-feature",
  "orchestrator_mode": "booster",
  "created_at": "2026-03-23T02:07:09Z",
  "updated_at": "2026-03-23T02:07:09Z",
  "authoritative_basis": "validated_response",
  "phase_just_validated": "specification",
  "current": {
    "feature_fingerprint": "sha256:...",
    "artifact_count": 3,
    "earliest_unresolved_phase": "none",
    "recommended_next_phase": "none",
    "recommended_next_subagent": "none"
  },
  "validation": {
    "response_file": "/abs/path/to/response.md",
    "response_sha256": "sha256:...",
    "response_schema_valid": true,
    "marker_validation_mode": "disabled",
    "marker_validation_passed": true,
    "validated_at": "2026-03-23T02:07:09Z",
    "validator": "skills/spec-orchestrator/scripts/validate_delegated_run.sh"
  }
}
```

## Allowed `authoritative_basis` values

- `validated_inspection`
- `validated_response`

## Refresh Rule

Refresh the routing snapshot only after a schema-valid delegated response is accepted.

Do not refresh the snapshot from terminal chatter or execution logs alone.
Do not write or refresh the snapshot for blocked transport, missing authoritative payloads, or manual work that happened after explicit orchestrator exit.
