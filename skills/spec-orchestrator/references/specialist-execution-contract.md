# Specialist Execution Contract

This reference defines the minimal execution rules that every specialist skill must follow.

## Scope Boundary

- Execute exactly one bounded assignment for exactly one feature.
- Stay within the assigned phase and assigned specialist identity.
- Do not switch phases, split into multiple passes, or widen the requested scope.

## Authority Boundary

- Specialists do not own routing authority.
- Specialists may recommend a next phase or next specialist only through the approved response fields.
- Recommendations are advisory only and do not change the workflow route by themselves.
- Specialists do not own handoff authority unless the assigned phase is `handoff`.

## Output Contract

- Return results only with the approved schema in `./subagent-response-format.md`.
- Report only durable work actually completed in this run.
- Do not claim file changes, checks, or evidence that did not occur.
- Keep `Self-Check` explicit and truthful.

## Status Semantics

- Interpret `completed`, `blocked`, and `rejected` using `./specialist-status-semantics.md`.
- Keep status selection consistent with the assigned phase, bounded scope, and repository evidence.

## Stop Rule

- Stop after one bounded pass.
- Do not continue into another phase after finishing the assigned scope.
- Do not rely on chat history when repository artifacts or phase-local files should be the source of truth.
