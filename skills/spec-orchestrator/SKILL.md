---
name: spec-orchestrator
description: Orchestrate feature delivery across spec, plan, tasks, implementation, verification, review, drift control, continuation, and handoff. Use this skill to detect the earliest valid phase, enforce stage gates, and explicitly invoke the correct specialist subagent for exactly one bounded unit of work.
---

# Spec Orchestrator

Coordinate feature delivery without collapsing all phases into one agent context.

This skill owns:

- feature resolution
- phase detection
- routing
- stage gating
- bounded batch selection
- review coordination
- drift escalation
- continuation
- handoff coordination

This skill does **not** own specialist phase execution when the corresponding specialist subagent exists.

## Required Delegation Rule

When a specialist subagent exists for the next valid phase, **use that subagent explicitly**.

Do not keep full specialist execution inside the orchestrator when the correct subagent is available.

The orchestrator must stay responsible for:

- identifying the target feature
- determining the earliest unresolved phase
- enforcing entry and exit gates
- selecting one bounded unit of work
- validating the returned result
- updating durable workflow notes

The orchestrator must **not** silently absorb specialist work that belongs to:

- `spec-analyst`
- `spec-planner`
- `spec-tasker`
- `spec-implementer`
- `spec-verifier`
- `spec-drift-check`
- `spec-handoff`

## Delegation Commands

Use these explicit commands when routing work:

- If `spec.md` is missing, ambiguous, or incomplete, **use subagent `spec-analyst` to create or revise `spec.md`**.
- If `plan.md` is missing, unresolved, or not execution-ready, **use subagent `spec-planner` to create or revise `plan.md`**.
- If `tasks.md` is missing, vague, oversized, or not verifiable, **use subagent `spec-tasker` to create or revise `tasks.md`**.
- If the next valid phase is implementation, **use subagent `spec-implementer` to complete exactly one bounded implementation batch**.
- If code or artifacts changed and evidence is required, **use subagent `spec-verifier` to verify the latest completed batch and record findings**.
- If the main question is whether current work exceeds the approved spec, **use subagent `spec-drift-check` to assess drift and write `drift.md`**.
- If work is pausing, resuming, blocked, or being transferred, **use subagent `spec-handoff` to write or update `handoff.md`**.

Do not phrase delegation as a preference.  
Write the instruction as an explicit action and begin it with the subagent identity and single-scope contract.

Preferred opening form:

**Use this exact opening pattern, replacing `X` with the target subagent name: `You are subagent X. Your task is to execute exactly one bounded unit of work for a single scope, produce a response in the predefined output format, and terminate immediately after returning the result.`**

## Use This Skill When

Use this skill when the request is about workflow orchestration, for example:

- determine the next valid phase for a feature
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

## Primary Artifact Convention

Use this feature layout:

- `specs/<feature>/spec.md`
- `specs/<feature>/plan.md`
- `specs/<feature>/tasks.md`

Secondary notes:

- `specs/<feature>/review.md`
- `specs/<feature>/drift.md`
- `specs/<feature>/handoff.md`

## Prompt Discovery Convention

When routing a specialist phase, use the mapping at `./references/codex-prompt-mapping.md`.

The orchestrator must:

1. Check `.codex/prompts/` for the exact mapped prompt for the assigned phase.
2. Also apply `.codex/prompts/speckit.constitution.md` when present.
3. If the mapped prompt is missing, search other prompt locations in the repository for an equivalent prompt.
4. If no repository prompt exists, continue using the assigned artifact contract and phase rules in this skill bundle.

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

## Operating Loop

Follow this loop on every orchestration pass:

1. Resolve the target feature.
2. Inspect feature artifacts and relevant code state.
3. Determine the earliest incomplete or conflicting phase.
4. Enforce the entry gate for that phase.
5. Discover the applicable repository prompt or template.
6. Use the correct specialist subagent for exactly one bounded unit of work.
7. Validate the subagent result against the exit gate.
8. Write or update durable workflow notes.
9. Either continue to the next valid phase or stop with blockers.

## Step 1: Resolve the Target Feature

Resolve the feature before routing.

Use this order:

1. If the user names the feature slug, use it.
2. Otherwise inspect `specs/`.
3. If exactly one plausible active feature exists, use it.
4. If multiple active candidates exist, stop and ask the user to choose.

Do not guess between multiple active features.

## Step 2: Inspect Current State

Inspect at least:

- whether `spec.md`, `plan.md`, and `tasks.md` exist
- whether `review.md`, `drift.md`, and `handoff.md` exist
- whether current code reflects completed or partial implementation
- whether `tasks.md` is actionable and bounded
- whether code changes exist that have not been verified

If available, read `handoff.md` first when resuming.

## Subagent locations

| Subagent | location |
| `spec-analyst` | `./agents/spec-analyst.md` |
| `spec-planner` | `./agents/spec-planner.md` |
| `spec-tasker` | `./agents/spec-tasker.md` |
| `spec-implementer` | `./agents/spec-implementer.md` |
| `spec-verifier` | `./agents/spec-verifier.md` |

## Spec Skill locations

| Skill | location |
| `spec-drift-check` | `./spec-drift-check/SKILL.md` |
| `spec-handoff` | `./spec-handoff/SKILL.md` |

## Shared Subagent Contracts

Keep shared lifecycle and response rules out of this main orchestrator skill file.
Use these references instead:

- lifecycle contract: `./references/subagent-lifecycle.md`
- response schema: `./references/subagent-response-format.md`
- prompt mapping: `./references/codex-prompt-mapping.md`
- prompt fallback and failure classification: `./references/subagent-prompt-fallbacks.md`

The orchestrator must delegate using those shared contracts rather than redefining them inline.
When validating a `blocked` or `rejected` result, use `./references/subagent-prompt-fallbacks.md`.

## Required Delegation Payload Elements

Every delegation payload must state all of the following:

- target feature
- artifact directory path
- exactly one assigned scope
- relevant artifact or bounded batch
- repository prompt mapping instruction
- explicit stop-after-completion instruction
- required response schema reference

The orchestrator validates the returned payload and decides the next phase.
If the task cannot be completed, the subagent must return a blocked or rejected result and stop.

## Routing Rules

Route to the earliest unresolved phase.

| Condition                                               | Next valid phase       | Required subagent  |
| ------------------------------------------------------- | ---------------------- | ------------------ |
| `spec.md` missing                                       | Specification          | `spec-analyst`     |
| `spec.md` incomplete or ambiguous                       | Specification          | `spec-analyst`     |
| `spec.md` ready and `plan.md` missing                   | Technical planning     | `spec-planner`     |
| `plan.md` incomplete or not execution-ready             | Technical planning     | `spec-planner`     |
| `spec.md` and `plan.md` ready, `tasks.md` missing       | Task decomposition     | `spec-tasker`      |
| `tasks.md` vague, oversized, or not verifiable          | Task decomposition     | `spec-tasker`      |
| actionable tasks remain and prerequisites are satisfied | Implementation         | `spec-implementer` |
| code or artifact batch changed and evidence is missing  | Verification           | `spec-verifier`    |
| the user asks whether artifacts and code are aligned    | Review                 | `spec-verifier`    |
| the main issue is scope mismatch or unexpected work     | Drift review           | `spec-drift-check` |
| the user asks to pause, resume, or transfer work        | Handoff / continuation | `spec-handoff`     |

If a later artifact exists while an earlier artifact is incomplete, route backward and record the mismatch in `review.md`.

## Explicit Routing Instructions

Apply these instructions exactly:

- If specification is the next valid phase, **use subagent `spec-analyst` to produce a complete, testable `spec.md`**.
- If planning is the next valid phase, **use subagent `spec-planner` to produce an implementation-ready `plan.md` aligned to `spec.md`**.
- If task decomposition is the next valid phase, **use subagent `spec-tasker` to produce bounded, ordered, verifiable tasks in `tasks.md`**.
- If implementation is the next valid phase, **use subagent `spec-implementer` to complete one bounded task batch and update relevant files**.
- If verification is the next valid phase, **use subagent `spec-verifier` to verify the latest completed batch against the spec and record evidence**.
- If drift handling is required, **use subagent `spec-drift-check` to assess whether current work exceeds approved scope and write the result to `drift.md`**.
- If handoff is required, **use subagent `spec-handoff` to package current workflow state in `handoff.md`**.

## Stage Gates

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

Whenever this orchestrator uses a specialist subagent, provide all of the following:

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
2. re-read primary artifacts
3. inspect current code and task state
4. determine the earliest incomplete phase again
5. use the correct subagent for that phase

Do not resume from the latest file that happens to exist.

## Handoff Behavior

At the end of any bounded orchestration pass, use subagent `spec-handoff` to update `handoff.md`.

Minimum `handoff.md` structure:

- current phase
- completed work
- pending work
- blockers
- recommended next step

## Durable Output Rule

Each orchestration pass must leave at least one durable update, such as:

- task state update in `tasks.md`
- review note in `review.md`
- drift note in `drift.md`
- handoff summary in `handoff.md`

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
