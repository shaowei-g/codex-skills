# Specialist Status Semantics

This reference defines the shared meaning of `completed`, `blocked`, and `rejected` for specialist skills.

## Completed

Return `completed` when all of the following are true:

- the assigned feature is clear
- the assigned phase is correct
- the entry gate for that phase is satisfied
- the bounded specialist scope was fully completed in this run
- any claimed durable outputs actually exist and match the repository state
- any markerized artifact changes remain consistent with `./artifact-acceptance-markers.md`

## Rejected

Return `rejected` when any of the following is true:

- the request contains multiple unrelated scopes
- the assigned input does not identify exactly one feature
- the assigned scope belongs to a different phase than the current specialist
- the request asks the specialist to continue into a second phase in the same run
- the entry gate is unsatisfied because the workflow is actually at an earlier phase
- the specialist would need to override routing, ownership, or bounded-scope rules to continue safely

## Blocked

Return `blocked` when all of the following are true:

- the assigned feature and phase are valid for the current specialist
- the bounded specialist scope is appropriate to attempt
- the work cannot be safely completed without missing prerequisites being resolved

Common `blocked` examples:

- required files or context are missing or unreadable
- necessary decisions, interfaces, dependencies, permissions, secrets, environments, or external systems are unavailable
- the assigned scope is valid but cannot be completed without expanding approved scope
- the repository state is insufficient to produce a truthful phase result

## Status Boundary Notes

- Use `rejected` for phase mismatch, routing mismatch, or bounded-scope violations.
- Use `blocked` for valid phase work that is currently prevented by missing prerequisites.
- Use `completed` only for work actually finished in this run.
- A `completed` specialist run may still leave the artifact in `draft` or `ready`; formal `accepted` markers belong to orchestrator gate acceptance.
- Do not use status selection to justify cross-phase work or silent scope expansion.

## Related References

- execution boundary: `./specialist-execution-contract.md`
- artifact markers: `./artifact-acceptance-markers.md`
- response schema: `./subagent-response-format.md`
