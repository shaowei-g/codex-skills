# Subagent Prompt Fallback and Failure Classification

This reference defines the required prompt lookup fallback chain and the criteria for returning `blocked` or `rejected` when a prompt or prerequisite is missing.

## Prompt Lookup Fallback Chain

Every subagent must resolve prompt guidance in this order:

1. Load the phase-specific primary prompt defined in `./codex-prompt-mapping.md` from the repository root.
2. Also load `.codex/prompts/speckit.constitution.md` when present and apply it as a governing constraint.
3. Load `.codex/prompts/speckit.clarify.md` only when clarification is explicitly part of the assigned scope or the primary prompt requires clarification before proceeding.
4. If the mapped primary prompt is missing, search other prompt locations in the repository for an equivalent prompt for the same phase.
5. If no equivalent repository prompt is found, fall back to the local phase rules in the assigned agent or skill file.

A subagent may never use fallback to jump to a different phase prompt.
For example, an implementation subagent may not substitute a planning prompt.

## Global Rejected Criteria

Return `rejected` when any of the following is true:

- the request contains multiple unrelated scopes
- the assigned scope belongs to a different phase than the current subagent
- the orchestrator payload does not identify exactly one feature
- the task requires using a different phase prompt instead of the mapped phase prompt
- the request asks the subagent to continue into a second phase in the same run
- the entry gate for the phase is not satisfied because the workflow is actually at an earlier phase

## Global Blocked Criteria

Return `blocked` when any of the following is true:

- the assigned phase is correct but required repository files or context are missing or unreadable
- the mapped prompt is missing and repository prompt search yields no equivalent prompt, and the local fallback rules are insufficient to safely complete the scope
- the mapped prompt exists but is internally inconsistent with governing constraints and the conflict cannot be resolved from repository artifacts
- the assigned work depends on a missing user decision, missing secret, missing environment, missing dependency, or missing external system access
- the assigned scope is valid but cannot be completed without expanding spec-approved scope

## Phase-Specific Prompt Expectations

### spec-viewer

Preferred prompt chain:

1. repository-local workflow inspection or feature-state prompt
2. `.codex/prompts/speckit.constitution.md` when present
3. local `spec-viewer` rules

Return `rejected` if the request asks `spec-viewer` to author phase-owned artifacts, implement work, or perform verification instead of inspection.
Return `blocked` if the phase is inspection but the repository artifacts or code needed to determine current state are missing or unreadable.

### spec-analyst

Preferred prompt chain:

1. `.codex/prompts/speckit.specify.md`
2. `.codex/prompts/speckit.constitution.md` when present
3. `.codex/prompts/speckit.clarify.md` only when clarification work is explicitly assigned or required
4. equivalent repository specification prompt
5. local `spec-analyst` rules

Return `rejected` if specification work is requested but the actual need is planning, tasks, implementation, or verification.
Return `blocked` if essential product intent is missing and clarification is required but cannot be resolved from artifacts or the assigned scope.

### spec-planner

Preferred prompt chain:

1. `.codex/prompts/speckit.plan.md`
2. `.codex/prompts/speckit.constitution.md` when present
3. equivalent repository planning prompt
4. local `spec-planner` rules

Return `rejected` if `spec.md` is missing, materially ambiguous, or not approved enough to support planning.
Return `blocked` if the phase is planning but technical constraints, interfaces, or dependencies required to produce a viable plan are unavailable.

### spec-tasker

Preferred prompt chain:

1. `.codex/prompts/speckit.tasks.md`
2. `.codex/prompts/speckit.constitution.md` when present
3. equivalent repository task decomposition prompt
4. local `spec-tasker` rules

Return `rejected` if `plan.md` is missing or not execution-ready.
Return `blocked` if the plan exists but cannot be decomposed into verifiable bounded tasks without unresolved architectural decisions.

### spec-implementer

Preferred prompt chain:

1. `.codex/prompts/speckit.implement.md`
2. `.codex/prompts/speckit.constitution.md` when present
3. equivalent repository implementation prompt
4. local `spec-implementer` rules

Return `rejected` if `tasks.md` is missing, the selected task slice is not bounded, or the requested work would combine multiple implementation batches.
Return `blocked` if the selected implementation slice is valid but cannot be completed because of missing environment setup, secrets, dependencies, or unresolved drift.

### spec-verifier

Preferred prompt chain:

1. `.codex/prompts/speckit.checklist.md`
2. `.codex/prompts/speckit.constitution.md` when present
3. equivalent repository verification or review prompt
4. local `spec-verifier` rules

Return `rejected` if there is nothing concrete to verify or if the request is actually asking for implementation rather than verification.
Return `blocked` if verification is the correct phase but evidence cannot be gathered because artifacts, code, test commands, fixtures, or runtime access are missing.

### spec-drift-check

Preferred prompt chain:

1. `.codex/prompts/speckit.analyze.md`
2. `.codex/prompts/speckit.constitution.md` when present
3. equivalent repository analysis prompt
4. local `spec-drift-check` rules

Return `rejected` if the request is actually asking for new specification authoring rather than drift assessment.
Return `blocked` if scope alignment cannot be determined from available artifacts and code evidence.

### spec-handoff

Preferred prompt chain:

1. repository handoff-oriented prompt if one exists
2. `.codex/prompts/speckit.checklist.md`
3. `.codex/prompts/speckit.constitution.md` when present
4. equivalent repository continuity or review prompt
5. local `spec-handoff` rules

Return `rejected` if the request asks the handoff skill to decide architecture, implement tasks, or verify behavior.
Return `blocked` if continuity notes cannot be prepared because the current phase, completed work, or blockers cannot be determined from repository state.

## Output Rule

When a subagent returns `blocked` or `rejected`, it must still complete the shared response format and make the reason explicit in `Blockers` or `Evidence` as appropriate.
