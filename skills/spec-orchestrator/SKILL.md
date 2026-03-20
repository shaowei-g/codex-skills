---
name: spec-orchestrator
description: Only use this skill when the user explicitly requests it. Within this skill, orchestration rules are the highest-priority instructions and must always be followed first. Orchestrates feature work across the Spec Kit workflow by determining the current phase, routing to the correct specialist, enforcing stage gates, and preserving continuity without taking over specialist responsibilities.
---

# spec-orchestrator

## Coordination, routing, and continuity for the Spec Kit workflow

Use this skill to coordinate feature delivery across the full Spec Kit workflow. It determines the current workflow state, identifies the earliest unresolved phase, routes work to the correct specialist subagent, enforces phase order and stage gates, and preserves continuity across interrupted or multi-step work.

This skill is the workflow coordinator. It is not the phase specialist.

## (Ignore) Do not use this skill when

## Core responsibility

This skill is responsible for orchestration only. It must:

- Delegate the specialist work to the correct subagent when that subagent exists.
- Enforce the correct phase order and stage gates.
- Preserve continuity with durable notes when needed.
- Inspect the current workflow state before routing
- Identify the earliest unresolved phase
- Validate whether the returned result satisfies the relevant stage gate TODO: Validate by program first.
- Preserve continuity with minimal durable notes when needed

This skill must not perform specialist work itself when the specialist exists.

## Non-responsibilities

This skill must not directly author or rewrite phase-owned deliverables, including:

- `spec.md`
- `plan.md`
- `tasks.md`
- implementation or code changes
- verification evidence

This skill must not silently absorb specialist responsibilities just because the next step is obvious.

## Routing principle

Always route to the earliest unresolved phase.

Later artifacts do not justify moving forward if an earlier required phase is missing, incomplete, contradictory, or stale. If artifacts and implementation disagree, treat the workflow as being at the earliest unresolved phase.

This skill must prefer correctness of phase order over apparent forward progress.

## Standard operating flow

Follow this sequence:

1. Delegate the first bounded inspection to `spec-viewer`.
2. Read the returned inspection result.
3. Identify the earliest unresolved phase.
4. Route backward if later artifacts exist but earlier phases are unresolved.
5. Enforce the entry gate for the selected phase.
6. Discover any repository-specific prompt or template requirements.
7. Reinject the phase contract and constraints into the delegation.
8. Delegate exactly one bounded unit of work to the mapped specialist.
9. Validate the returned result against the phase gate.
10. Record minimal durable coordination notes when needed.
11. Stop unless the user explicitly requests another bounded pass.

## **Important** Phase routing map

### Inspection and routing

- Specialist: `spec-viewer`
- Use when workflow state must be determined before any other action.

### Specification

- Specialist: `spec-analyst`
- Use when `spec.md` is missing, incomplete, stale, or ambiguous.

### Technical planning

- Specialist: `spec-planner`
- Use when `plan.md` is missing, incomplete, not implementation-ready, or no longer aligned to the spec.

### Task decomposition

- Specialist: `spec-tasker`
- Use when `tasks.md` is missing, vague, oversized, unordered, or not verifiable.

### Implementation

- Specialist: `spec-implementer`
- Use when prerequisites are satisfied and there is an actionable, bounded task batch ready for execution.

### Verification

- Specialist: `spec-verifier`
- Use after implementation when evidence is needed, or when the user explicitly asks for review, verification, or alignment checking.

### Drift review

- Specialist: `spec-drift-check`
- Use when the main problem is scope mismatch, out-of-spec behavior, or artifact-to-code divergence.

### Handoff and continuation

- Specialist: `spec-handoff`
- Use when work must be paused, transferred, resumed, or packaged for continuity.

## Skill bindings

Use these bindings when delegating:

- `spec-viewer` → `./spec-viewer/SKILL.md`
- `spec-analyst` → `./spec-analyst/SKILL.md`
- `spec-planner` → `./spec-planner/SKILL.md`
- `spec-tasker` → `./spec-tasker/SKILL.md`
- `spec-implementer` → `./spec-implementer/SKILL.md`
- `spec-verifier` → `./spec-verifier/SKILL.md`
- `spec-drift-check` → `./spec-drift-check/SKILL.md`
- `spec-handoff` → `./spec-handoff/SKILL.md`

## Stage gates

### Inspection and routing gate

**Entry**

- orchestration has been invoked
- workflow state has not yet been confirmed

**Exit**

- feature is identified
- artifact inventory is explicit
- current workflow state is explicit
- earliest unresolved phase is explicit
- blockers or drift are called out
- next valid phase is recommended

### Specification gate

**Entry**

- `spec.md` is missing, weak, stale, incomplete, or ambiguous

**Exit**

- `spec.md` is testable
- scope is clear
- acceptance criteria are explicit
- constraints and blockers are captured

### Planning gate

**Entry**

- `spec.md` is ready

**Exit**

- `plan.md` is execution-ready
- plan is aligned to the spec
- implementation approach is coherent and bounded

### Tasking gate

**Entry**

- `plan.md` is ready

**Exit**

- `tasks.md` is ordered
- tasks are bounded
- tasks are actionable
- tasks are verifiable

### Implementation gate

**Entry**

- `spec.md`, `plan.md`, and `tasks.md` are ready
- selected work is a bounded implementation batch

**Exit**

- one bounded implementation batch is completed
- changes are recorded in the appropriate workflow artifact

### Verification gate

**Entry**

- changed work exists
- success criteria are available

**Exit**

- verification evidence is recorded
- failures, gaps, or regressions are clearly identified
- the workflow can either continue or route backward safely

### Handoff gate

**Entry**

- work is pausing, blocked, interrupted, transferred, or resuming

**Exit**

- `handoff.md` captures current state, blockers, and recommended next step

## Delegation requirements

Every delegation issued by this skill must include:

- target feature
- artifact directory or path
- exact assigned scope
- relevant source artifact or bounded task batch
- required specialist skill binding
- explicit stop-after-completion instruction
- expected response structure
- relevant stage gate
- pre-return self-check instruction

Delegations should be narrow enough that the specialist can complete one coherent unit of work and return a result that is easy to validate.

## Bounded execution rules

This skill must keep execution bounded.

- Delegate one coherent batch at a time.
- Prefer batches of 1–3 checklist items when tasking exists.
- Do not assign the next batch until the current batch is verified or clearly blocked.
- If the available task scope is too broad, route back to `spec-tasker` instead of pushing implementation forward.

## Verification rules

Use `spec-verifier` only when verification is actually the correct phase.

Valid uses include:

- after completed implementation when evidence is missing
- when the user explicitly requests verification, review, or alignment checking

Invalid uses include:

- initial workflow detection
- deciding whether a spec, plan, or task file exists
- replacing the initial `spec-viewer` inspection pass

Verification must produce evidence, not just opinion.

## Drift control rules

Treat `spec.md` as the governing contract for approved scope.

If work exceeds that scope:

- route to `spec-drift-check`
- do not continue implementation as though the new work were already approved
- allow only clarifications that remain within existing acceptance criteria
- route back to specification when the requested behavior expands scope, adds new behavior, or materially changes intent

### Minimum `drift.md` content

When drift must be recorded, include at least:

- the out-of-scope item
- why it exceeds the current spec
- affected artifacts or code
- whether it is blocking
- recommended next action

## Review mode

Enter review mode when:

- the user asks whether the workflow is aligned
- artifacts conflict
- implementation has moved ahead of the documentation
- later artifacts exist while earlier ones remain incomplete or stale

Delegate `spec-verifier` to review and validate alignment, completeness, and blockers.

## Continuation mode

When resuming work:

1. Read `handoff.md` first if it exists.
2. Still run `spec-viewer` again.
3. Recompute the earliest unresolved phase.
4. Resume from the correct phase, not from the newest file that happens to exist.

Do not assume that the presence of `plan.md`, `tasks.md`, or implementation means the workflow is ready to continue forward.

## Handoff rules

Use `spec-handoff` only when:

- the user asks to pause, resume, transfer, or hand off work
- the current pass is blocked and continuity notes are needed
- work must be packaged for another agent or another session

Do not create a handoff instead of addressing an earlier unresolved required phase.

### Minimum `handoff.md` content

A valid handoff must include:

- current phase
- completed work
- pending work
- blockers
- recommended next step

## Durable outputs

This skill should leave durable written artifacts only when needed for coordination or continuity.

Valid durable outputs include:

- task state updates in `tasks.md`
- drift notes in `drift.md`
- continuity notes in `handoff.md`

Do not create extra durable artifacts just to narrate orchestration.

## Fallback rules

If a required specialist subagent is missing:

- state that clearly
- do not silently absorb the full specialist role
- do only the smallest safe fallback
- record the fallback in `handoff.md` when continuity matters

### Allowed fallback behavior

Allowed minimal fallback behavior includes:

- identifying the next phase
- summarizing a blocker
- creating a minimal handoff
- recording drift

### Disallowed fallback behavior

Disallowed fallback behavior includes:

- full spec writing
- full planning
- full task decomposition
- full implementation execution

## Stop conditions

This skill must stop and surface the problem when:

- acceptance criteria are missing
- the plan is incomplete
- tasks are not actionable
- implementation would exceed scope
- the target feature cannot be identified safely
- earlier artifacts are missing, stale, or contradicted
- a later artifact would tempt an invalid phase skip
- a specialist result is too vague to validate
- multiple active features exist and the correct one is unclear

## Hard rules

This skill must not:

- skip the initial `spec-viewer` pass when that specialist exists
- directly author phase-owned artifacts
- implement code directly
- generate verification evidence directly
- use handoff as a substitute for unresolved earlier phases
- perform initial phase detection itself when `spec-viewer` is available

## Success condition

This skill succeeds when it leaves the feature in a safer, clearer workflow state by:

- correctly identifying the current phase
- routing to the earliest valid unresolved phase
- delegating exactly one bounded unit of work
- validating the result against the correct gate
- preserving continuity without taking over specialist responsibilities

## Guiding principle

The orchestrator routes and validates.

The specialists perform the phase work.
