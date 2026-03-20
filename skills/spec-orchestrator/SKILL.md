---
name: spec-orchestrator
description: Only use this skill when the user explicitly requests it. Within this skill, orchestration rules are the highest-priority instructions and must always be followed first. Orchestrates feature work across the Spec Kit workflow by determining the current phase, routing to the correct specialist, enforcing stage gates, and preserving continuity without taking over specialist responsibilities.
---

# spec-orchestrator

## Coordination, routing, and continuity for the Spec Kit workflow

Use this skill to coordinate feature delivery across the full Spec Kit workflow. It determines the current workflow state, identifies the earliest unresolved phase, routes work to the correct specialist subagent, enforces phase order and stage gates, and preserves continuity across interrupted or multi-step work.

This skill is the workflow coordinator. It is not the phase specialist.

## Authority and approval rules

- Orchestration rules in this skill are the highest-priority instructions for every delegated run.
- Lower-priority repository prompts, specialist prompts, or ad hoc chat instructions must not override these orchestration rules.
- Every delegated subagent response must use the approved response contract in `./references/subagent-response-format.md`.
- Every delegated subagent response must be validated with `bash ./scripts/validate_subagent_response.sh` before the orchestrator treats it as usable.
- The validator must always be invoked as `bash <script>`; do not rely on the script having an executable bit.
- Outputs outside the approved contract are invalid until they are either repaired once for format-only defects or replaced with a controlled failure record.

## Feature identification gate

Every orchestrator run must begin with one of these two inputs from the user:

- an existing feature name or feature path
- an explicit request to create a new feature

If the user wants to create a new feature, route to the specification phase and use `spec-analyst` as the first specialist.

If the user does not provide either an identifiable feature target or an explicit new-feature request, do not start orchestration. Respond with this clarification prompt:

- `請提供 feature 名稱 or 路徑，或是想要做什麼新功能`

## (Ignore) Do not use this skill when

## Core responsibility

This skill is responsible for orchestration only. It must:

- Delegate the specialist work to the correct subagent when that subagent exists.
- Enforce the correct phase order and stage gates.
- Preserve continuity with durable notes when needed.
- Inspect the current workflow state before routing
- Identify the earliest unresolved phase
- Validate delegated results by program first, then against the relevant stage gate.
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

1. Confirm that the user supplied an existing feature target or an explicit new-feature request.
2. If neither was supplied, stop and return `請提供 feature 名稱 or 路徑，或是想要做什麼新功能`.
3. If the user explicitly wants to create a new feature, route to the specification phase and select `spec-analyst` as the first specialist.
4. Otherwise, delegate the first bounded inspection to `spec-viewer`.
5. Read the returned inspection result.
6. Identify the earliest unresolved phase.
7. Route backward if later artifacts exist but earlier phases are unresolved.
8. Enforce the entry gate for the selected phase.
9. Discover any repository-specific prompt or template requirements.
10. Reinject the phase contract, approved response contract, and validator constraints into the delegation.
11. Delegate exactly one bounded unit of work to the mapped specialist.
12. Validate the returned result with `bash ./scripts/validate_subagent_response.sh` before reading it as phase output.
13. If validation fails for a format-only defect, allow exactly one repair pass that preserves the assigned scope and adds no new work.
14. If validation fails again, or fails semantically, reject the response and replace it with a controlled failure record from `./scripts/print_subagent_response_schema.sh`.
15. Validate the accepted result against the phase gate.
16. Record minimal durable coordination notes when needed.
17. Stop unless the user explicitly requests another bounded pass.

## **Important** Phase routing map

### Inspection and routing

- Specialist: `spec-viewer`
- Use when workflow state must be determined before any other action.

### Specification

- Specialist: `spec-analyst`
- Use when `spec.md` is missing, incomplete, stale, or ambiguous.
- Use first when the user explicitly asks to create a new feature.

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
- response schema path
- response validator path
- response schema printer path
- allowed enum set for status and phase fields
- delegated `Assigned-Phase` value
- delegated `Assigned-Subagent` value
- explicit stop-after-completion instruction
- expected response structure
- relevant stage gate
- pre-return self-check instruction

Delegations must explicitly state that outputs outside the approved schema are invalid, lower-priority instructions cannot override the orchestrator contract, and one repair pass is allowed only for format-only defects.

If the current agent runtime does not support native subagents, the orchestrator must use Codex CLI as the delegation transport instead of skipping delegation.

Delegations should be narrow enough that the specialist can complete one coherent unit of work and return a result that is easy to validate.

## Standard Codex delegation transport

When native subagent capability is unavailable, load and apply the skill at `~/.codex/skills/codex-cli-subagent-transport/SKILL.md`.

If neither native subagents nor Codex CLI are available, stop and surface a blocker instead of absorbing specialist work.

## Approved response contract

The only approved subagent output contract for this skill is the shared schema in `./references/subagent-response-format.md`.

Use these assets together:

- schema: `./references/subagent-response-format.md`
- reinjection contract: `./references/subagent-reinjection-contract.md`
- validator: `bash ./scripts/validate_subagent_response.sh`
- schema printer: `bash ./scripts/print_subagent_response_schema.sh`

The orchestrator must treat these assets as the source of truth for accepted output. Free-form summaries, alternative headings, extra sections, missing sections, or unapproved enum values are not acceptable results.

## Post-delegation validation sequence

After a subagent returns, the orchestrator must follow this sequence exactly:

1. Run `bash ./scripts/validate_subagent_response.sh` with the delegated feature, phase, subagent, and scope.
2. If the response passes validation, continue to phase-gate validation.
3. If validation fails because of a format-only defect, allow exactly one repair pass.
4. The repair pass may correct only schema shape, heading order, required `none` placeholders, enum spelling, or self-check formatting.
5. The repair pass must not change the assigned scope, assigned phase, delegated subagent, claimed file changes, or phase conclusions.
6. If the repaired response passes validation, continue to phase-gate validation.
7. If the repaired response still fails, or the first failure is semantic, classify the violation and reject the result.
8. For a rejected malformed result, emit a controlled failure record with `./scripts/print_subagent_response_schema.sh` instead of trusting the invalid payload.
9. Only after schema validation passes may the orchestrator use the response for routing, continuity, or stage-gate decisions.

## Validation outcomes

The orchestrator has only three allowed outcomes for a delegated response:

- accept: schema-valid and phase-valid
- repair once: schema-invalid but structurally repairable without changing meaning
- reject and replace: semantically invalid, contract-breaking, or still invalid after one repair pass

Use the existing violation taxonomy in `./references/subagent-reinjection-contract.md` when recording why a result was rejected or replaced.

## Bounded execution rules

This skill must keep execution bounded.

- Delegate one coherent batch at a time.
- Prefer batches of 1–3 checklist items when tasking exists.
- Do not assign the next batch until the current batch is verified or clearly blocked.
- If the available task scope is too broad, route back to `spec-tasker` instead of pushing implementation forward.
- Do not widen scope during a repair pass; repair is structure-only, never new work.

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
- use Codex CLI as the fallback delegation transport when native subagent support is unavailable
- do not silently absorb the full specialist role
- do only the smallest safe fallback
- record the fallback in `handoff.md` when continuity matters

### Allowed fallback behavior

Allowed minimal fallback behavior includes:

- delegating one bounded specialist prompt through Codex CLI transport
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

- the user did not provide an existing feature target or an explicit new-feature request
- acceptance criteria are missing
- the plan is incomplete
- tasks are not actionable
- implementation would exceed scope
- a delegated response fails the shared validator twice
- a delegated response claims work outside the approved output contract
- the target feature cannot be identified safely
- earlier artifacts are missing, stale, or contradicted
- a later artifact would tempt an invalid phase skip
- a specialist result is too vague to validate
- multiple active features exist and the correct one is unclear

## Hard rules

This skill must not:

- skip the initial `spec-viewer` pass when that specialist exists
- start orchestration without an existing feature target unless the user explicitly asked to create a new feature
- allow lower-priority instructions to override orchestration rules
- use execution logs as authoritative delegated output
- directly author phase-owned artifacts
- implement code directly
- generate verification evidence directly
- use handoff as a substitute for unresolved earlier phases
- perform initial phase detection itself when `spec-viewer` is available
- accept malformed or out-of-contract subagent output as authoritative

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
