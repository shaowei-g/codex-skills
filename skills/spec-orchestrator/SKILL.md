---
name: spec-orchestrator
description: Orchestrate GitHub Spec Kit workflows across spec, plan, tasks, implementation, verification, review, and handoff. Use for staged feature delivery, phase detection, continuation, drift control, and delegation to specialist subagents.
---

# Spec Orchestrator

Coordinate GitHub Spec Kit feature delivery without collapsing all work into one agent context.

This skill owns:

- feature resolution
- phase detection
- routing
- stage gating
- bounded batch selection
- drift control
- review
- continuation
- handoff

This skill does **not** own full specialist execution when an appropriate specialist subagent is available.

Preferred companions:

- `spec-analyst`
- `spec-planner`
- `spec-tasker`
- `spec-implementer`
- `spec-verifier`
- `spec-drift-check`
- `spec-handoff`

## Use This Skill When

Use this skill when the request is about orchestration or workflow state, for example:

- determine the next valid phase for a feature
- continue an interrupted Spec Kit workflow
- decide whether the workflow can move forward or must loop back
- decide what should happen next without skipping stages
- prepare a handoff
- coordinate specialist subagents across multiple phases

Examples:

- "Continue feature `checkout-flow` from the correct phase."
- "Figure out what phase this Spec Kit feature is in."
- "Decide whether this feature can move forward or must loop back to an earlier phase."
- "Resume this partially completed feature safely."
- "Prepare a handoff for the next agent."

## Do Not Use This Skill When

Do not use this skill when the user clearly wants one specialist phase directly, for example:

- write `spec.md`
- create `plan.md`
- decompose `plan.md` into tasks
- implement a specific task
- verify a specific completed batch
- capture verification evidence or findings for a completed batch
- prepare only a handoff summary for another agent

In those cases, use the relevant specialist directly unless the user explicitly asks for orchestration.

## Primary Artifact Convention

Prefer this feature layout:

- `.specify/specs/<feature>/spec.md`
- `.specify/specs/<feature>/plan.md`
- `.specify/specs/<feature>/tasks.md`

Secondary notes:

- `.specify/specs/<feature>/review.md`
- `.specify/specs/<feature>/drift.md`
- `.specify/specs/<feature>/handoff.md`

If the repository uses a different but clearly established Spec Kit-compatible layout, follow the repository convention instead of forcing this structure.

## Template Fallback Rule

If these reference files exist, reuse them:

- `references/review-checklist.md`
- `references/drift-report-template.md`
- `references/handoff-template.md`

If the helper skills exist, prefer them for the focused operation:

- use `spec-drift-check` when the main question is whether artifacts, requests, or code exceed the current spec
- use `spec-handoff` when the main question is how to package current workflow state for pause, resume, or transfer

If a referenced template does **not** exist, do not block execution.  
Create a minimal structured note inline using the required fields defined in this skill.

## Core Rules

- Never silently skip a required earlier phase.
- Never implement directly from a raw request unless `spec.md`, `plan.md`, and `tasks.md` are all sufficiently prepared.
- Never absorb scope expansion into implementation without recording drift.
- Never approve materially broader scope on behalf of the user.
- Prefer one bounded unit of work at a time.
- Persist workflow state in files, not only in chat.
- If artifacts and code disagree, treat the workflow as being at the earliest unresolved phase.
- If multiple plausible features exist and no single target is clear, stop and ask the user to identify the feature.

## Operating Loop

Follow this loop on every orchestration pass:

1. Resolve the target feature.
2. Inspect feature artifacts and relevant code state.
3. Determine the earliest incomplete or conflicting phase.
4. Enforce the entry gate for that phase.
5. Delegate exactly one bounded unit of work.
6. Validate the specialist result against the exit gate.
7. Write or update durable notes.
8. Either continue to the next valid phase or stop with blockers.

Do not keep implicit workflow state only in chat.

## Step 1: Resolve the Target Feature

Resolve the feature before routing.

Use this order:

1. If the user names the feature slug, use it.
2. Otherwise inspect `.specify/specs/`.
3. If exactly one plausible active feature exists, use it.
4. If multiple active candidates exist, stop and ask the user to choose.

Do not guess between multiple active features.

## Step 2: Inspect Current State

Inspect at least:

- whether `spec.md`, `plan.md`, and `tasks.md` exist
- whether `review.md`, `drift.md`, and `handoff.md` exist
- whether the current codebase reflects completed or partial implementation
- whether `tasks.md` is current, actionable, and bounded
- whether code changes exist that have not been verified

If available, read `handoff.md` first when resuming.

## Routing Rules

Use the earliest unresolved phase. Never skip over a missing prerequisite.

| Condition                                                              | Next valid phase       | Delegate to                              |
| ---------------------------------------------------------------------- | ---------------------- | ---------------------------------------- |
| `spec.md` missing                                                      | Specification          | `spec-analyst`                           |
| `spec.md` exists but scope or acceptance criteria are incomplete       | Specification          | `spec-analyst`                           |
| `spec.md` ready and `plan.md` missing                                  | Technical planning     | `spec-planner`                           |
| `plan.md` exists but is incomplete, unresolved, or not execution-ready | Technical planning     | `spec-planner`                           |
| `spec.md` and `plan.md` are ready, `tasks.md` missing                  | Task decomposition     | `spec-tasker`                            |
| `tasks.md` exists but tasks are vague, oversized, or not verifiable    | Task decomposition     | `spec-tasker`                            |
| actionable tasks remain and prerequisites are satisfied                | Implementation         | `spec-implementer`                       |
| code or artifact batch changed and evidence is missing                 | Verification           | `spec-verifier`                          |
| the user asks for alignment review or artifacts conflict               | Review                 | `spec-verifier`                          |
| the user asks to pause, resume, or hand off                            | Handoff / continuation | orchestrator plus the correct next phase |

If a later artifact exists while an earlier one is incomplete, route backward and record the mismatch in `review.md`.

## Stage Gates

### 1. Specification

Entry:

- `spec.md` is missing, incomplete, or ambiguous
- acceptance criteria are missing
- scope boundaries are not explicit

Exit:

- `spec.md` exists
- problem and intended user-facing outcome are explicit
- acceptance criteria are explicit and testable
- non-goals, constraints, and scope boundaries are clear enough to detect drift
- open questions are either resolved or labeled as blockers

Block when:

- acceptance criteria are absent
- the request is too vague to define safely

### 2. Technical Planning

Entry:

- `spec.md` is complete enough to plan against

Exit:

- `plan.md` describes the intended approach
- touched systems, modules, or interfaces are identified
- dependencies, risks, and verification strategy are recorded
- the plan maps back to the spec without inventing new scope

Block when:

- critical implementation areas are still unexplained
- the plan introduces scope not present in `spec.md`

### 3. Task Decomposition

Entry:

- `plan.md` is complete enough to break into execution work

Exit:

- `tasks.md` exists
- tasks are ordered, actionable, and bounded
- each task or batch is verifiable
- tasks cover planned work without adding extra features

Block when:

- tasks are too vague to assign
- tasks are too large to verify in one pass
- tasks depend on missing planning detail

### 4. Implementation

Entry:

- `spec.md`, `plan.md`, and `tasks.md` are ready
- the selected batch is small and coherent
- dependencies for that batch are satisfied

Exit:

- the delegated batch is complete
- task state reflects reality
- required code, tests, and notes are updated
- detected drift is recorded immediately

Block when:

- implementation would exceed the approved spec
- the batch depends on incomplete prior work
- the tasks are not actionable enough for bounded execution

### 5. Verification

Entry:

- a code or artifact batch changed
- success criteria exist

Exit:

- evidence is recorded against acceptance criteria
- failures, gaps, and uncertainties are written down
- if verification fails, the workflow routes back to the earliest incomplete phase

Block when:

- there is no defined success criteria
- implementation cannot be judged against the spec

### 6. Handoff / Continuation

Entry:

- work is pausing, blocked, interrupted, or being resumed

Exit:

- `handoff.md` states the current phase, completed work, pending work, blockers, and recommended next step
- the next agent can continue without prior chat history

## Delegation Contract

When delegating to a specialist, always provide:

- feature slug
- artifact directory path
- current phase
- why this is the next valid phase
- exact files to read first
- current scope boundaries from `spec.md`
- the bounded unit or batch to complete
- the expected deliverable
- exit criteria
- explicit drift-handling instructions

Use the smallest correct context.  
Do not forward unrelated discussion history when the artifacts already contain the needed state.

## Specialist Return Contract

A specialist must return enough structured information for the orchestrator to decide what happens next.

Require the specialist result to include:

- work completed
- files created or updated
- blockers
- unresolved questions
- drift detected, if any
- verification or evidence status, if relevant
- recommended next phase

If the result is too vague to validate against the exit gate, do not advance the workflow.

## Bounded Execution Rules

Implementation must stay small.

- Select one coherent batch at a time.
- Prefer 1 to 3 checklist items, not the whole backlog.
- Do not assign a new batch until the prior batch is verified or explicitly marked blocked.
- If `tasks.md` is not decomposed enough to support bounded work, route back to `spec-tasker`.

## Drift-Control Rules

Treat `spec.md` as the contract.

- If requested or discovered work exceeds the current spec, stop and record drift.
- If implementation reveals a clarification that does not expand behavior, label it as clarification and continue only if it stays within the existing acceptance criteria.
- If implementation reveals new behavior, new integrations, new surfaces, or materially broader scope, route back to specification before further implementation.
- Never hide scope expansion as cleanup, follow-up, or a small extra.

When drift appears, update `drift.md`.
If available, prefer using the `spec-drift-check` helper skill for the focused drift decision and note generation.

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
- later artifacts exist while earlier ones are incomplete

In review mode:

1. compare `spec.md` to `plan.md`
2. compare `plan.md` to `tasks.md`
3. compare `tasks.md` to current implementation
4. compare implementation to verification evidence
5. record findings in `review.md`

Classify findings as:

- blocker
- drift
- stale artifact
- verified

Do not silently repair multiple gaps during review mode unless the user asks to continue after the review.

## Continuation Mode

Use continuation mode when resuming interrupted work.

In continuation mode:

1. read `handoff.md` first if present
2. re-read the primary artifacts
3. inspect current code and task state
4. determine the earliest incomplete phase again
5. resume from that phase, not from the latest file that happens to exist

If prior implementation exists but lacks verification, prefer verification or route back to the earliest incomplete phase revealed by the evidence.

## Handoff Behavior

At the end of any bounded orchestration pass, update `handoff.md`.
If available, prefer using the `spec-handoff` helper skill for the focused handoff packaging step.

Minimum `handoff.md` structure:

- current phase
- completed work
- pending work
- blockers
- recommended next step

Keep it concise and scannable.

## Durable Output Rule

Each orchestration pass must leave at least one durable update, such as:

- task state update in `tasks.md`
- review note in `review.md`
- drift note in `drift.md`
- handoff summary in `handoff.md`

Prefer short structured notes over long prose.

## Fallback Rules

If a named specialist does not exist:

- say so clearly
- do not silently convert the orchestrator into the full specialist
- either stop, or perform the smallest safe fallback needed to preserve workflow continuity
- record the fallback in `handoff.md`

Allowed fallback examples:

- identifying the correct next phase
- drafting a blocker summary
- creating a minimal handoff
- recording drift

Disallowed fallback examples unless the user explicitly asks:

- writing a full replacement spec
- producing the complete plan
- doing the full task decomposition
- performing the full implementation pass

## Stop Conditions

Stop and report blockers when:

- acceptance criteria are missing
- the plan is incomplete
- tasks are not actionable
- implementation would exceed approved scope
- the target feature cannot be identified safely
- a required earlier phase artifact is missing or contradicted by later work
- the specialist result is too incomplete to validate

Do not continue past these conditions.

## Trigger Examples

Trigger this skill:

- "Use Spec Kit to resume feature `audit-log-export`."
- "What is the next valid phase for this partially completed feature?"
- "Review whether the plan and tasks still match the shipped code."
- "Continue this feature without skipping required stages."
- "Prepare a handoff for the next agent."

Do not trigger this skill:

- "Write `plan.md` for feature `audit-log-export`."
- "Decompose this plan into tasks."
- "Implement task 4 from `tasks.md`."
- "Run verification on the latest implementation batch."

Those requests should use the relevant specialist directly unless the user asks for orchestration or stage selection.
