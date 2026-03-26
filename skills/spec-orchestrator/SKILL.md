---
name: spec-orchestrator
description: Only use this skill when the user explicitly requests it. Orchestrates Spec Kit workflow state, routes to the earliest unresolved phase, validates delegated outputs, preserves continuity without taking over specialist work, and supports an explicit user-gated booster mode for end-to-end feature advancement.
---

# spec-orchestrator

Use this skill only when the user explicitly requests Spec Kit workflow orchestration.

This skill coordinates workflow state and delegation. It does not own phase deliverables when a specialist exists.

## Routing authority

- This skill has final authority over routing, delegated result acceptance, and continuity decisions.
- Specialists may recommend work informally, but routing authority remains with the orchestrator.
- The orchestrator must not absorb specialist-owned phase work when the mapped specialist exists.
- For existing features with unclear or conflicting state, inspect current repository state or use a schema-valid inspection result before making a strong routing claim.

## Gate policy

### Feature identification gate

Every run must begin with one of:

- an existing feature name or feature path
- an explicit request to create a new feature

If neither is provided, stop and return:

- `請提供 feature 名稱 or 路徑，或是想要做什麼新功能`

### Execution modes

- Default mode is `standard`.
- `booster` is unlocked only when the current user request explicitly contains `mode: booster`.

### Routing rule

- Always route to the earliest unresolved phase.
- Later artifacts never justify skipping an earlier unresolved phase.
- If artifacts, implementation, or workflow notes disagree, route backward to the earliest unresolved phase.
- If the user explicitly requests a new feature, start at specification with `spec-analyst`.
- Otherwise, inspect current state first with `spec-viewer`.

### Routing snapshot shortcut

- Before starting a fresh inspection run, the orchestrator may consult:
  - `.codex/spec-orchestrator-state/<feature>/routing-snapshot.json`
- A routing snapshot is reusable only when:
  - the current feature fingerprint matches the snapshot fingerprint
  - the snapshot points to a schema-valid delegated response
- A routing snapshot is a coordination cache, not formal acceptance by itself.

### Delegation rule

- In `standard` mode, delegate exactly one bounded unit of work and then stop after that delegated step is accepted, blocked, or rejected.
- In `booster` mode, the orchestrator may chain multiple delegated steps for the same feature, but only one phase-scoped delegated step at a time.
- Keep assigned phase and assigned subagent fixed within each delegated step.
- At most one delegated execution attempt is allowed per delegated step.
- After each accepted delegated step in `booster` mode, recompute the earliest unresolved phase before deciding whether to continue.

### Specialist bindings

- inspection → `spec-viewer`
- specification → `spec-analyst`
- planning → `spec-planner`
- task decomposition → `spec-tasker`
- implementation → `spec-implementer`
- verification → `spec-verifier`
- drift check → `spec-drift-check`
- handoff → `spec-handoff`

## Lean operating mode

Use the smallest reliable context set for each run.

### Happy-path read order

For a standard run or a single booster step, load only this minimum set before delegating:

1. feature target plus repo-local routing snapshot lookup
2. the assigned phase prompt from `.codex/prompts/`
3. `.codex/prompts/speckit.constitution.md` when present
4. the mapped specialist skill for the assigned phase
5. only the feature artifacts needed for that phase
6. `bash ./scripts/validate_delegated_run.sh` for acceptance

## Validation policy

- Every delegated response must match the approved status-only schema in:
  - `./references/subagent-response-format.md`
- Every delegated response must be validated with:
  - `bash ./scripts/validate_subagent_response.sh`
- YAML front matter is not an acceptance gate.
- Do not require `validate_artifact_markers.sh` for delegated-run acceptance.
- Always invoke validators as `bash <script>`.
- One repair pass is allowed only for format-only defects after an authoritative delegated payload exists.
- If a delegated attempt fails to produce an authoritative payload, classify that delegated step as `blocked` and stop.

### Snapshot refresh rule

- After accepting a schema-valid delegated response, refresh the routing snapshot for that feature and verify the written file by rereading it immediately.
- Use:
  - `bash ./scripts/validate_delegated_run.sh`

## Stop conditions

Stop the current mode cycle and surface the blocker when any of the following is true:

- no feature target or explicit new-feature request was provided
- the correct feature cannot be identified safely
- the earliest unresolved phase cannot be satisfied from current prerequisites
- a delegated result fails validation and is not safely repairable
- a delegated result violates phase, scope, ownership, or routing boundaries
- continuation would require skipping an earlier unresolved phase
- the assigned specialist is unavailable and transport fallback is also unavailable
- the delegated execution attempt for the current step failed to produce an authoritative delegated payload
- `booster` would need to guess the next phase or continue after any non-`completed` delegated status

## Continuity rule

- Record only minimal durable coordination notes when continuity is needed.
- Prefer existing workflow artifacts over chat history when resuming.
- Treat a later resume after blocked transport as a fresh orchestrator run, not as hidden continuation inside the old booster cycle.
- Repo-local routing snapshots are allowed as minimal durable coordination notes.
