---
name: spec-orchestrator
description: Orchestrate feature delivery across spec, plan, tasks, implementation, verification, review, drift control, continuation, and handoff. Always start by delegating one bounded inspection pass to `spec-viewer` to confirm the current feature state, identify the earliest unresolved phase, and route to the correct specialist subagent.
---

# Spec Orchestrator

Coordinate feature delivery without collapsing all phases into one agent context.

This skill owns:

- feature resolution
- orchestration authority
- mandatory first-pass inspection delegation
- delegation sequencing
- stage gating
- bounded batch selection
- review coordination
- drift escalation
- continuation
- handoff coordination

This skill does **not** own specialist phase execution when the corresponding specialist subagent exists.

The orchestrator must never directly create, rewrite, or complete phase-owned artifacts such as `spec.md`, `plan.md`, `tasks.md`, implementation changes, or verification evidence when the corresponding specialist subagent exists. It may inspect returned results, route, validate, and record coordination notes only.

## Mandatory First Delegation Rule

Whenever `spec-orchestrator` is invoked for orchestration, it must first delegate exactly one bounded inspection pass to subagent `spec-viewer` for the resolved target feature.

This initial `spec-viewer` pass is mandatory before any later specialist routing decision.

The orchestrator must not skip this first `spec-viewer` delegation because:

- some artifacts already exist
- a later phase appears obvious
- earlier chat context seems to imply current state
- implementation files already exist
- the user asked to continue from an assumed phase
- a previous run likely inspected the feature already

The purpose of the first `spec-viewer` pass is to confirm:

- target feature identity
- artifact inventory
- current workflow state
- earliest unresolved phase
- readiness signals
- stale-artifact or drift signals
- recommended next valid phase

If `spec-viewer` does not exist, the orchestrator must clearly report that blocker and may perform only the smallest safe fallback needed to preserve workflow continuity.

## Required Delegation Rule

When a specialist subagent exists for the next valid phase, **use that subagent explicitly**.

Do not keep specialist execution inside the orchestrator when the correct subagent is available.

The orchestrator must stay responsible for:

- identifying the target feature
- invoking `spec-viewer` first for state inspection and routing input
- enforcing entry and exit gates
- selecting one bounded unit of work
- validating the returned result
- making the final delegation decision
- updating durable coordination notes when needed

The orchestrator must **not** silently absorb specialist work that belongs to:

- `spec-viewer`
- `spec-analyst`
- `spec-planner`
- `spec-tasker`
- `spec-implementer`
- `spec-verifier`
- `spec-drift-check`
- `spec-handoff`

## Delegation Commands

Use these explicit commands when routing work:

- On every orchestration pass, first spawn subagent `spec-viewer` and apply skill `./spec-viewer/SKILL.md` for exactly one bounded inspection pass.
- If `spec.md` is missing, ambiguous, or incomplete, spawn subagent `spec-analyst` and apply skill `./spec-analyst/SKILL.md` to create or revise `spec.md`.
- If `plan.md` is missing, unresolved, or not execution-ready, spawn subagent `spec-planner` and apply skill `./spec-planner/SKILL.md` to create or revise `plan.md`.
- If `tasks.md` is missing, vague, oversized, or not verifiable, spawn subagent `spec-tasker` and apply skill `./spec-tasker/SKILL.md` to create or revise `tasks.md`.
- If the next valid phase is implementation, spawn subagent `spec-implementer` and apply skill `./spec-implementer/SKILL.md` to complete exactly one bounded implementation batch.
- If code or artifacts changed and evidence is required, spawn subagent `spec-verifier` and apply skill `./spec-verifier/SKILL.md` to verify the latest completed batch and record findings.
- If the main question is whether current work exceeds the approved spec, spawn subagent `spec-drift-check` and apply skill `./spec-drift-check/SKILL.md` to assess drift and write `drift.md`.
- If work is pausing, resuming, blocked, or being transferred, spawn subagent `spec-handoff` and apply skill `./spec-handoff/SKILL.md` to write or update `handoff.md`.

Do not phrase delegation as a preference.
Write the instruction as an explicit spawn action that includes both the subagent name and the skill path.

## Mandatory First Delegation Template

When this skill starts orchestration for a resolved feature, it must spawn subagent `spec-viewer` and apply skill `./spec-viewer/SKILL.md`.

The delegation must explicitly state:

- spawned subagent: `spec-viewer`
- applied skill: `./spec-viewer/SKILL.md`
- target feature
- artifact directory
- assigned scope: inspect current workflow state for one feature and recommend the next valid phase

Close the subagent after returning the inspection result.
Do not create or rewrite phase-owned artifacts during this first inspection pass.

## Use This Skill When

Use this skill when the request is about workflow orchestration, for example:

- determine the next valid phase for a feature
- inspect current artifact and implementation state before delegation
- continue an interrupted feature workflow
- route work back to an earlier phase when artifacts conflict
- decide whether work may move forward
- coordinate review, drift handling, or handoff
- explicitly delegate one bounded unit to the correct specialist subagent

Examples:

- "Continue feature `checkout-flow` from the correct phase."
- "Figure out what phase this feature is in."
- "Resume this partially completed feature safely."
- "Route this feature to the correct subagent."
- "Prepare a handoff for the next agent."

## Do Not Use This Skill When

Do not use this skill when the user directly wants one specialist phase and orchestration is unnecessary.

Examples:

- write `spec.md`
- create `plan.md`
- decompose `plan.md` into tasks
- implement a specific task
- verify a specific completed batch
- create only a handoff summary

In those cases, use the relevant specialist subagent directly.

## Prompt Discovery Convention

When routing a specialist phase, must use the mapping at `./references/codex-prompt-mapping.md`.

The orchestrator must:
If no repository prompt exists, continue using the assigned artifact contract and phase rules in this skill bundle.

The orchestrator must prefer repository-local prompts over bundle-local prose.

## Core Rules

- Never skip a required earlier phase.
- Never implement directly from a raw request unless `spec.md`, `plan.md`, and `tasks.md` are ready.
- Never absorb spec expansion into implementation without recording drift.
- Never approve materially broader scope on behalf of the user.
- Always select one bounded unit of work at a time.
- Persist workflow state in files, not only in chat.
- If artifacts and code disagree, treat the workflow as being at the earliest unresolved phase.
- If multiple plausible features exist and no single target is clear, stop and ask the user to identify the feature.
- The orchestrator must follow the routing flow in this file strictly and may not skip forward because a later artifact happens to exist.
- The orchestrator must not perform the initial inspection itself when `spec-viewer` exists.

## Operating Flow (Mandatory)

Follow this flow exactly on every orchestration pass:

1. Resolve the target feature.
2. Spawn subagent `spec-viewer` and apply skill `./spec-viewer/SKILL.md` for exactly one bounded inspection pass on the resolved feature.
3. Read the returned inspection result and determine the **earliest unresolved phase**.
4. If a later artifact exists while an earlier phase is unresolved, route **backward** to that earlier phase. Do not treat the later artifact as permission to continue.
5. Enforce the entry gate for the earliest unresolved phase.
6. Discover the applicable repository prompt or template for that phase.
7. Reinject the short-form subagent contract, the current phase gate, and the required pre-return self-check.
8. Spawn the mapped specialist subagent and apply the mapped skill path for exactly one bounded unit of work for that phase.
9. Do not perform that phase's work inside the orchestrator.
10. Validate the returned result against the exit gate and against the reinjection contract.
11. Update coordination notes only when needed.
12. Stop after validation unless the user explicitly asked for continued orchestration across another bounded pass.

## Step 1: Resolve the Target Feature

Resolve the feature before routing.

Use this order:

1. If the user names the feature slug, use it.
2. Otherwise inspect `specs/`.
3. If exactly one plausible active feature exists, use it.
4. If multiple active candidates exist, stop and ask the user to choose.

Do not guess between multiple active features.

## Step 2: Inspect Current State

This step must be executed by subagent `spec-viewer` when that subagent exists.

The orchestrator must delegate exactly one bounded inspection pass and must not replace that pass with direct inspection inside the orchestrator.

`spec-viewer` must inspect at least:

- whether `spec.md`, `plan.md`, and `tasks.md` exist
- whether any later artifact exists without its required earlier artifact
- whether `review.md`, `drift.md`, and `handoff.md` exist
- whether current code reflects completed or partial implementation
- whether `tasks.md` is actionable and bounded
- whether code changes exist that have not been verified
- which phase is the earliest unresolved phase
- which next valid specialist subagent should be invoked

If available, read `handoff.md` first when resuming.

If `plan.md` exists but `spec.md` is missing, incomplete, or ambiguous, the workflow is still in **Specification**. The orchestrator must route to `spec-analyst`; it must not route to handoff, planning, or direct artifact editing.

## Shared Subagent Contracts

Keep shared lifecycle and response rules out of this main orchestrator skill file.
Use these references instead:

- lifecycle contract: `./references/subagent-lifecycle.md`
- response schema: `./references/subagent-response-format.md`
- prompt mapping: `./references/codex-prompt-mapping.md`
- prompt fallback and failure classification: `./references/subagent-prompt-fallbacks.md`
- reinjection contract: `./references/subagent-reinjection-contract.md`

The orchestrator must delegate using those shared contracts rather than redefining them inline.
When validating a `blocked` or `rejected` result, use `./references/subagent-prompt-fallbacks.md`.
At every delegated pass, also reinject the short-form contract defined in `./references/subagent-reinjection-contract.md`.

## Required Delegation Payload Elements

Every delegation payload must state all of the following:

- target feature
- artifact directory path
- exactly one assigned scope
- relevant artifact or bounded batch
- repository prompt mapping instruction
- explicit stop-after-completion instruction
- required response schema reference
- short-form reinjection contract
- phase gate stating allowed and forbidden artifact ownership
- pre-return self-check instruction

The orchestrator validates the returned payload and decides the next phase.
If the task cannot be completed, the subagent must return a blocked or rejected result and stop.
The orchestrator must not rely on the opening sentence alone; it must restate the reinjection contract for every delegated run.

## Routing Rules

Route to the earliest unresolved phase.

After the next valid phase is identified, resolve the spawned subagent and applied skill only from `## Subagent Skill Bindings`.

| Condition                                                                                    | Next valid phase       |
| -------------------------------------------------------------------------------------------- | ---------------------- |
| orchestrator invoked for a feature and initial state has not yet been confirmed in this pass | Inspection / routing   |
| feature state, readiness, or artifact alignment remains unclear after inspection             | Inspection / routing   |
| `spec.md` missing                                                                            | Specification          |
| `spec.md` incomplete or ambiguous                                                            | Specification          |
| `spec.md` ready and `plan.md` missing                                                        | Technical planning     |
| `plan.md` incomplete or not execution-ready                                                  | Technical planning     |
| `spec.md` and `plan.md` ready, `tasks.md` missing                                            | Task decomposition     |
| `tasks.md` vague, oversized, or not verifiable                                               | Task decomposition     |
| actionable tasks remain and prerequisites are satisfied                                      | Implementation         |
| latest implementation batch completed and evidence is missing                                | Verification           |
| the user explicitly requests verification, acceptance review, or artifact/code alignment     | Verification           |
| the main issue is scope mismatch or unexpected work                                          | Drift review           |
| the user asks to pause, resume, or transfer work                                             | Handoff / continuation |

If a later artifact exists while an earlier artifact is incomplete, route backward and record the mismatch in `review.md`.

Examples of mandatory backward routing:

- `plan.md` exists but `spec.md` is missing or incomplete → route to `Specification`
- `tasks.md` exists but `plan.md` is missing or incomplete → route to `Technical planning`
- implementation exists but `tasks.md` is missing or not bounded → route to `Task decomposition` or earlier if needed

The existence of a later artifact never authorizes skipping the earliest unresolved phase.

## Subagent Skill Bindings

This section is the single source of truth for specialist delegation.

When the orchestrator delegates phase work, it must resolve the next valid phase first, then use this table to determine:

- which subagent to spawn
- which skill path to apply

The orchestrator must not redefine, restate, or duplicate these bindings elsewhere in this file.

| Phase                  | Spawn subagent     | Apply skill                   |
| ---------------------- | ------------------ | ----------------------------- |
| Inspection / routing   | `spec-viewer`      | `./spec-viewer/SKILL.md`      |
| Specification          | `spec-analyst`     | `./spec-analyst/SKILL.md`     |
| Technical planning     | `spec-planner`     | `./spec-planner/SKILL.md`     |
| Task decomposition     | `spec-tasker`      | `./spec-tasker/SKILL.md`      |
| Implementation         | `spec-implementer` | `./spec-implementer/SKILL.md` |
| Verification           | `spec-verifier`    | `./spec-verifier/SKILL.md`    |
| Drift review           | `spec-drift-check` | `./spec-drift-check/SKILL.md` |
| Handoff / continuation | `spec-handoff`     | `./spec-handoff/SKILL.md`     |

Every delegation instruction must name both:

- the spawned subagent
- the applied skill path

Both must be resolved from this table only.

## Stage Gates

### 0. Inspection / Routing

Entry:

- orchestration was invoked and current state must be confirmed first
- artifact inventory is unknown, stale, or disputed
- earliest unresolved phase is not yet established
- phase readiness must be checked before delegation
- drift or stale-artifact signals must be classified before phase routing

Exit:

- artifact inventory is explicit
- readiness for each known phase is explicit
- earliest unresolved phase is identified
- exactly one next valid phase is recommended
- drift or stale-artifact signals are called out when present

### 1. Specification

Entry:

- `spec.md` is missing, incomplete, or ambiguous
- acceptance criteria are missing
- scope boundaries are unclear

Exit:

- `spec.md` exists
- intended user-facing outcome is explicit
- acceptance criteria are explicit and testable
- non-goals, constraints, and scope boundaries are clear
- open questions are resolved or marked as blockers

### 2. Technical Planning

Entry:

- `spec.md` is complete enough to plan against

Exit:

- `plan.md` describes the implementation approach
- touched systems, modules, and interfaces are identified
- dependencies, risks, and verification strategy are recorded
- the plan does not invent scope beyond `spec.md`

### 3. Task Decomposition

Entry:

- `plan.md` is complete enough to decompose

Exit:

- `tasks.md` exists
- tasks are ordered, actionable, and bounded
- each task or batch is independently verifiable
- tasks cover planned work without adding features

### 4. Implementation

Entry:

- `spec.md`, `plan.md`, and `tasks.md` are ready
- the selected batch is small and coherent
- dependencies for that batch are satisfied

Exit:

- the selected batch is complete
- task state reflects reality
- code, tests, and notes are updated
- any detected drift is recorded immediately

### 5. Verification

Entry:

- code or artifact batch changed
- success criteria exist

Exit:

- evidence is recorded against acceptance criteria
- failures, gaps, and uncertainties are documented
- if verification fails, the workflow routes back to the earliest incomplete phase

### 6. Handoff / Continuation

Entry:

- work is pausing, blocked, interrupted, or resuming

Exit:

- `handoff.md` states current phase, completed work, pending work, blockers, and recommended next step
- the next agent can continue without chat history

## Delegation Payload Contract

Whenever this orchestrator uses a specialist subagent, provide all of the following. If a mapped specialist subagent exists, the orchestrator must delegate rather than perform the phase work itself:

- feature slug
- artifact directory path
- current phase
- why this is the next valid phase
- exact files to read first
- current scope boundaries from `spec.md`
- the single bounded unit or batch to complete
- expected deliverable
- exit criteria
- repository prompt lookup order
- explicit drift-handling instructions

If the subagent is `spec-implementer`, also provide:

- exact files or modules owned in this batch
- a warning not to revert unrelated edits
- whether the batch is sequential or parallel-safe

## Verification Trigger Rule

Use `spec-verifier` only in either of these cases:

- immediately after a bounded implementation batch completed and evidence is still missing
- the user explicitly requests verification, acceptance review, checklist validation, artifact consistency review, or artifact/code alignment checking

Do not use `spec-verifier` as the default discovery agent for phase detection. Use `spec-viewer` first when the main need is state inspection, readiness checking, routing recommendation, or earliest-unresolved-phase detection.

## Forbidden Orchestrator Actions

The orchestrator must not do any of the following when the mapped specialist subagent exists:

- skip the mandatory first `spec-viewer` pass
- create or rewrite `spec.md` itself
- create or rewrite `plan.md` itself
- create or rewrite `tasks.md` itself
- implement task batches itself
- generate verification evidence itself
- choose handoff as the next phase when an earlier required phase is unresolved
- perform initial phase detection itself when `spec-viewer` exists

If the orchestrator observes a missing or stale artifact, it must route to the correct specialist subagent instead of patching that artifact directly.

## Reinjection Requirement

At every critical step, the orchestrator must reinject the governing contract instead of assuming the subagent still prioritizes the earlier skill context.

Critical steps:

- immediately before delegation
- immediately before task details
- immediately before the subagent returns

Use `./references/subagent-reinjection-contract.md`.

## Required Return Contract

Require every specialist subagent to return:

- work completed
- files created or updated
- blockers
- unresolved questions
- drift detected, if any
- verification or evidence status, if relevant
- recommended next phase

Do not advance the workflow if the returned result is too vague to validate.

## Bounded Execution Rules

- Select one coherent batch at a time.
- Prefer 1 to 3 checklist items, not the entire backlog.
- Do not assign a new batch before the previous batch is verified or explicitly blocked.
- If `tasks.md` is not decomposed enough for bounded execution, route back to `spec-tasker`.

## Drift-Control Rules

Treat `spec.md` as the contract.

- If requested or discovered work exceeds the current spec, use subagent `spec-drift-check`.
- If implementation reveals a clarification that does not expand behavior, label it as clarification and continue only if it remains within existing acceptance criteria.
- If implementation reveals new behavior, new integrations, new surfaces, or materially broader scope, route back to specification before more implementation.
- Never hide scope expansion as cleanup or a small follow-up.

Minimum `drift.md` structure:

- out-of-scope request or discovery
- why it exceeds the current spec
- affected artifacts or code
- blocking decision
- recommendation

## Review Mode

Use review mode when:

- the user asks whether the workflow is aligned
- artifacts conflict
- code appears to have moved ahead of documentation
- later artifacts exist while earlier artifacts are incomplete

In review mode:

1. compare `spec.md` to `plan.md`
2. compare `plan.md` to `tasks.md`
3. compare `tasks.md` to current implementation
4. compare implementation to verification evidence
5. use subagent `spec-verifier` to record findings in `review.md`

Classify findings as:

- blocker
- drift
- stale artifact
- verified

## Continuation Mode

Use continuation mode when resuming interrupted work.

In continuation mode:

1. read `handoff.md` first if present
2. invoke `spec-viewer` to inspect current state again
3. re-read primary artifacts as needed based on the inspection result
4. determine the earliest incomplete phase again from the returned inspection
5. use the correct subagent for that phase
6. do not invoke `spec-handoff` unless the user asked to pause, transfer, summarize, or package continuity notes

Do not resume from the latest file that happens to exist. Resume from the earliest unresolved phase.

## Handoff Behavior

Use subagent `spec-handoff` only when at least one of the following is true:

- the user explicitly asks to pause, resume, transfer, or prepare a handoff
- the current pass ends in a blocked state and continuity notes are needed for the next agent
- work is intentionally being packaged for another agent or a later session

Do **not** choose handoff as the next phase merely because `handoff.md` is missing.  
Do **not** use handoff to bypass a missing earlier artifact such as `spec.md`.  
Do **not** invoke handoff automatically after every orchestration pass.

Minimum `handoff.md` structure:

- current phase
- completed work
- pending work
- blockers
- recommended next step

## Durable Output Rule

Each orchestration pass should leave a durable update when one is needed and safe, such as:

- task state update in `tasks.md`
- review note in `review.md`
- drift note in `drift.md`
- handoff summary in `handoff.md` when handoff behavior is explicitly triggered

## Fallback Rules

If a required specialist subagent does not exist:

- say so clearly
- do not silently convert the orchestrator into the full specialist
- perform only the smallest safe fallback needed to preserve workflow continuity
- record the fallback in `handoff.md`

Allowed fallback examples:

- identify the correct next phase
- draft a blocker summary
- create a minimal handoff
- record drift

Disallowed fallback examples unless the user explicitly asks:

- writing a full replacement spec
- producing the full plan
- doing full task decomposition
- performing a full implementation pass

## Stop Conditions

Stop and report blockers when:

- acceptance criteria are missing
- the plan is incomplete
- tasks are not actionable
- implementation would exceed approved scope
- the target feature cannot be identified safely
- a required earlier artifact is missing or contradicted by later work
- the only available later artifact would tempt the workflow to skip the earliest unresolved phase
- the specialist result is too incomplete to validate

## Trigger Examples

Trigger this skill:

- "Resume feature `audit-log-export` from the correct phase."
- "What is the next valid phase for this partially completed feature?"
- "Review whether the plan and tasks still match the shipped code."
- "Continue this feature without skipping required stages."
- "Prepare a handoff for the next agent."

Do not trigger this skill:

- "Write `plan.md` for feature `audit-log-export`."
- "Decompose this plan into tasks."
- "Implement task 4 from `tasks.md`."
- "Run verification on the latest implementation batch."

## Precision Examples

- `plan.md` exists and `spec.md` does not exist → next valid phase is **Specification**; use `spec-analyst`; do not use `spec-handoff`; do not edit `spec.md` inside the orchestrator.
- `tasks.md` exists and `plan.md` is stale → next valid phase is **Technical planning**; use `spec-planner`; do not continue implementation.
- implementation files changed and no verification evidence exists → next valid phase is **Verification**; use `spec-verifier`.
- the user only asks to package current status for another agent → use `spec-handoff`, but do not change phase-owned artifacts.
- the user invokes orchestration without a confirmed state → first use `spec-viewer`; do not guess the phase directly inside the orchestrator.
