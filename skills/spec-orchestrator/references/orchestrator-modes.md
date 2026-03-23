# Orchestrator Modes

This reference defines the user-visible execution modes for `spec-orchestrator`.

## Default Rule

- The default mode is `standard`.
- `booster` is unlocked only when the current user request explicitly contains `mode: booster`.
- Do not infer `booster` from broad wording such as “finish it”, “do the whole feature”, or “end to end”.
- When a request does not explicitly include `mode: booster`, the orchestrator must behave as `standard`.

## Standard Mode

Use `standard` mode unless the user explicitly unlocks `booster`.

Behavior:

- route to the earliest unresolved phase
- delegate one bounded specialist step
- validate that delegated result
- refresh snapshot state when allowed
- stop after the current delegated step is accepted, blocked, or rejected
- report the next bounded step instead of continuing automatically

## Booster Mode

`booster` allows the orchestrator to advance one feature through multiple sequential phases within the same user request.

### Booster Goal

- drive the feature from its current authoritative state toward the furthest valid workflow state
- prefer reaching accepted handoff when prerequisites and repository conditions allow
- still stop immediately on blockers, rejections, validation failures, or ambiguous routing

### Booster Loop

For each booster cycle:

1. determine the earliest unresolved phase from validated markers, a reusable routing snapshot, or a schema-valid inspection result
2. delegate exactly one bounded specialist step for that phase
3. validate the delegated result with `bash ./scripts/validate_delegated_run.sh`
4. refresh snapshot state when acceptance rules allow
5. recompute the earliest unresolved phase from current validated state
6. continue only when the next phase is unambiguous and its prerequisites are already satisfied

### Booster Boundaries

- `booster` does not let one specialist execute multiple phases in one response
- each delegated step keeps one assigned phase, one assigned subagent, and one bounded scope
- each delegated step gets at most one execution attempt
- a format-only repair pass is still limited to one repair for the current delegated payload
- do not preload all specialists or all prompts before they are needed
- do not use `booster` to bypass missing prerequisites, authority limits, marker validation, or write-ownership rules
- do not keep going after any delegated `blocked` or `rejected` result
- do not keep going after transport failure or missing authoritative payload
- do not keep going when continuation would require guessing the route instead of reading current validated state

## Terminal Conditions

Stop the current mode cycle when any of these become true:

- the delegated step returns `blocked`
- the delegated step returns `rejected`
- the delegated payload fails validation and cannot be safely repaired
- transport does not produce an authoritative `response_file`
- the next phase is ambiguous or its prerequisites are missing
- accepted handoff is reached
- no further unresolved phase remains under the repository workflow rules

## Relationship to Specialist Rules

`booster` changes only orchestrator behavior.

It does not change these specialist rules:

- one bounded assignment per specialist run
- no routing authority
- no cross-phase execution
- no ownership drift
- use the approved compact response schema only
