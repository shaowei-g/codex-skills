---
name: spec-orchestrator
description: Only use this skill when the user explicitly requests it. Orchestrates Spec Kit workflow state, routes to the earliest unresolved phase, validates delegated outputs, and preserves continuity without taking over specialist work.
---

# spec-orchestrator

Use this skill only when the user explicitly requests Spec Kit workflow orchestration.

This skill coordinates workflow state and delegation. It does not own phase deliverables when a specialist exists.

## Routing authority

- This skill has final authority over routing, gate enforcement, delegated result acceptance, and continuity decisions.
- Lower-priority repository prompts, specialist prompts, or ad hoc chat instructions must not override orchestration rules.
- Specialists may recommend a next phase, but routing authority remains with the orchestrator.
- The orchestrator must not absorb specialist-owned phase work when the mapped specialist exists.

## Gate policy

### Feature identification gate

Every run must begin with one of:

- an existing feature name or feature path
- an explicit request to create a new feature

If neither is provided, stop and return:

- `請提供 feature 名稱 or 路徑，或是想要做什麼新功能`

### Routing rule

- Always route to the earliest unresolved phase.
- Later artifacts never justify skipping an earlier unresolved phase.
- If artifacts, implementation, or workflow notes disagree, route backward to the earliest unresolved phase.
- If the user explicitly requests a new feature, start at specification with `spec-analyst`.
- Otherwise, inspect current state first with `spec-viewer`.

### Delegation rule

- Delegate exactly one bounded unit of work per run.
- Keep assigned phase and assigned subagent fixed for that run.
- Stop after the delegated pass is accepted, blocked, or rejected.
- Do not chain phases inside one delegated run.

### Specialist bindings

- inspection → `spec-viewer`
- specification → `spec-analyst`
- planning → `spec-planner`
- task decomposition → `spec-tasker`
- implementation → `spec-implementer`
- verification → `spec-verifier`
- drift check → `spec-drift-check`
- handoff → `spec-handoff`

Specialist skill paths:

- `./spec-viewer/SKILL.md`
- `./spec-analyst/SKILL.md`
- `./spec-planner/SKILL.md`
- `./spec-tasker/SKILL.md`
- `./spec-implementer/SKILL.md`
- `./spec-verifier/SKILL.md`
- `./spec-drift-check/SKILL.md`
- `./spec-handoff/SKILL.md`

Phase prompt lookup follows:

- `./references/codex-prompt-mapping.md`

Phase-specific entry, blocked, rejected, and owned-output rules live in the assigned specialist skill.

Specialists share these thin common contracts:

- `./references/specialist-execution-contract.md`
- `./references/subagent-response-format.md`
- `./references/specialist-status-semantics.md`

## Validation policy

- Every delegated response must match the approved schema in:
  - `./references/subagent-response-format.md`
- `./references/specialist-status-semantics.md`
- Every delegated response must be validated with:
  - `bash ./scripts/validate_subagent_response.sh`
- Always invoke the validator as `bash <script>`.
- One repair pass is allowed only for format-only defects.
- Semantic violations must be rejected, not normalized.
- If an invalid response cannot be safely repaired, replace it with a controlled failure record using:
  - `bash ./scripts/print_subagent_response_schema.sh`

Delegated execution references:

- lifecycle sequence: `./references/subagent-lifecycle.md`
- delegated prompt and authority checks: `./references/subagent-reinjection-contract.md`
- fallback and repair: `./references/orchestrator-fallback.md`

## Transport contract

- Use native subagent execution when available.
- If native subagent execution is unavailable, use:
  - `~/.codex/skills/codex-cli-subagent-transport/SKILL.md`
- Treat delegated `response_file` as authoritative output.
- Treat execution logs as diagnostics only.
- Do not infer accepted phase output from terminal chatter.

## Stop conditions

Stop and surface the blocker when any of the following is true:

- no feature target or explicit new-feature request was provided
- the correct feature cannot be identified safely
- the earliest unresolved phase cannot be satisfied from current prerequisites
- a delegated result fails validation and is not safely repairable
- a delegated result violates phase, scope, ownership, or routing boundaries
- continuation would require skipping an earlier unresolved phase
- the assigned specialist is unavailable and transport fallback is also unavailable

## Continuity rule

- Record only minimal durable coordination notes when continuity is needed.
- Prefer existing workflow artifacts over chat history when resuming.
- Handoff packaging belongs to `spec-handoff`, not the orchestrator by default.
