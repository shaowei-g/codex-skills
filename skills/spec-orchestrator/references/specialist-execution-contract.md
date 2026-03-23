# Specialist Execution Contract

This reference defines the minimal execution rules that every specialist skill must follow.

## Scope Boundary

- Execute exactly one bounded assignment for exactly one feature.
- Stay within the assigned phase and assigned specialist identity.
- Do not switch phases, split into multiple passes, or widen the requested scope, even when the orchestrator is operating in `booster` mode.

## Authority Boundary

- Specialists do not own routing authority.
- When the assigned scope includes phase-owned file updates, the delegated specialist must have workspace write capability.
- Read-only exploration or Q&A agents are not valid substitutes for write-owning specialist runs.
- Specialists must not accept a prompt that treats their phase judgment as a foregone conclusion when the assignment still requires truthful current-state evidence.
- Specialists may recommend a next phase or next specialist only through the approved response fields.
- Recommendations are advisory only and do not change the workflow route by themselves.
- Advisory recommendation fields do not count as exercising routing authority, so `Self-Check` should keep `chose_next_phase = false` and `chose_next_subagent = false`.
- Specialists do not own handoff authority unless the assigned phase is `handoff`.

## Output Contract

- Return results only with the approved schema in `./subagent-response-format.md`.
- Report only durable work actually completed in this run.
- Do not claim file changes, checks, or evidence that did not occur.
- When direct repo writes are unavailable but the assigned output content is complete, use the approved `Artifacts` payload section so the orchestrator can materialize the files.
- Keep `Self-Check` explicit and truthful.

## Artifact Marker Discipline

- When writing or updating markerized workflow artifacts, preserve the YAML front matter contract from `./artifact-acceptance-markers.md`.
- Keep marker blocks validator-compatible with `../scripts/validate_artifact_markers.sh`; do not emit malformed or partial front matter.
- Specialists may initialize or update `status: draft` or `status: ready` when that reflects the real artifact state.
- Specialists must not self-promote artifacts to formal acceptance; `approved_by_orchestrator: true` and `status: accepted` are orchestrator-owned.
- `completed` in the response schema does not automatically mean the artifact is formally accepted for the next phase.

## Status Semantics

- Interpret `completed`, `blocked`, and `rejected` using `./specialist-status-semantics.md`.
- Keep status selection consistent with the assigned phase, bounded scope, and repository evidence.

## Stop Rule

- Stop after one bounded pass.
- Do not continue into another phase after finishing the assigned scope.
- Do not rely on chat history when repository artifacts or phase-local files should be the source of truth.


## Delegated Write Fallback

- A specialist may complete a write-owning scope without direct delegated file writes only by returning exact artifact payloads in the approved `Artifacts` section.
- Artifact payload fallback does not permit extra phases, extra files outside the bounded scope, or unowned marker promotion.
- If the delegated environment prevents writes and the specialist cannot provide truthful final artifact content, return `blocked`, not `completed`.
