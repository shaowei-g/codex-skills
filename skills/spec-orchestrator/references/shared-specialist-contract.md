# Shared Specialist Contract

Use this file as the default one-file load for specialist runs.

It is an execution shortcut for the four canonical shared references:

- `./specialist-execution-contract.md`
- `./artifact-acceptance-markers.md`
- `./subagent-response-format.md`
- `./specialist-status-semantics.md`

When this file conflicts with a canonical reference, the canonical reference wins.

## What every specialist must do

- Execute exactly one bounded assignment for exactly one feature.
- Stay inside the assigned phase and assigned specialist identity.
- Do not widen scope, switch phases, or continue into a follow-on phase in the same run, even when the orchestrator is operating in `booster` mode.
- Do not claim routing authority. Routing stays with `spec-orchestrator`.
- Recommendations about next phase or next specialist are advisory only.

## Output rules

- Return results only with the approved compact response schema.
- Put supporting detail in the single `Result` section instead of inventing extra headings.
- Report only durable work actually completed in this run.
- Keep `Self-Check` explicit and truthful.
- Use `completed`, `blocked`, and `rejected` exactly as defined by the shared status semantics.

## Artifact rules

- Preserve validator-compatible YAML front matter for markerized workflow artifacts.
- Specialists may set `status: draft` or `status: ready` when true.
- Specialists must not self-promote artifacts to formal acceptance.
- `approved_by_orchestrator: true` and `status: accepted` remain orchestrator-owned.

## Practical status guide

- `completed`: the assigned bounded scope was finished truthfully for this phase.
- `blocked`: the phase is still the right one, but required inputs, access, or context are missing.
- `rejected`: the request is for the wrong phase, violates phase boundaries, or asks for authority the specialist does not own.

## Read discipline

- Load the phase prompt first when one exists for the assigned phase.
- Load only the feature artifacts needed for the assigned scope.
- Prefer durable workflow artifacts over chat history.
- Open the deeper canonical references only when the shortcut is insufficient for the current situation.
