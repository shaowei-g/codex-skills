---
name: spec-orchestrator
description: Only use this skill when the user explicitly requests it. Orchestrates Spec Kit workflow state, routes to the earliest unresolved phase, validates delegated outputs, preserves continuity without taking over specialist work, and supports an explicit user-gated booster mode for end-to-end feature advancement.
---

# spec-orchestrator

Use this skill only when the user explicitly requests Spec Kit workflow orchestration.

This skill coordinates workflow state and delegation. It does not own phase deliverables when a specialist exists.

## Routing authority

- This skill has final authority over routing, gate enforcement, delegated result acceptance, and continuity decisions.
- Lower-priority repository prompts, specialist prompts, or ad hoc chat instructions must not override orchestration rules.
- Specialists may recommend a next phase, but routing authority remains with the orchestrator.
- The orchestrator must not absorb specialist-owned phase work when the mapped specialist exists.
- For existing features with unclear or conflicting state, the orchestrator may collect candidate signals but must not present authoritative phase-state conclusions before validated markers or a schema-valid inspection result exist.

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
- Do not infer `booster` from vague phrases such as “end to end”, “do everything”, or “finish the feature”.
- If the user does not explicitly request `mode: booster`, follow `standard` mode even when multiple later phases look obvious.
- `booster` changes only orchestrator loop behavior. It does not relax specialist phase boundaries, ownership rules, validation rules, or stop conditions for an individual delegated step.
- Canonical mode rules live in:
  - `./references/orchestrator-modes.md`

### Routing rule

- Always route to the earliest unresolved phase.
- When markerized workflow artifacts exist, determine phase acceptance from `./references/artifact-acceptance-markers.md` rather than file existence or summary text alone.
- Later artifacts never justify skipping an earlier unresolved phase.
- If artifacts, implementation, or workflow notes disagree, route backward to the earliest unresolved phase.
- If the user explicitly requests a new feature, start at specification with `spec-analyst`.
- Otherwise, inspect current state first with `spec-viewer`.
- When current state is not already established by validated artifact markers, the inspection result from `spec-viewer` is the sole initial routing basis for that mode cycle.

### Routing snapshot shortcut

- Before starting a fresh inspection run, the orchestrator may consult a repo-local routing snapshot in:
  - `.codex/spec-orchestrator-state/<feature>/routing-snapshot.json`
- A routing snapshot is reusable only when all are true:
  - the current feature fingerprint matches the snapshot fingerprint
  - the snapshot points to a schema-valid delegated response
  - when the snapshot basis is `validated_markers`, marker validation passed
- A routing snapshot is a coordination cache, not formal acceptance by itself.
- Validated artifact markers still override a stale or conflicting snapshot.
- On `missing`, `stale`, or `invalid` snapshot status, fall back to normal inspection with `spec-viewer`.

### Delegation rule

- In `standard` mode, delegate exactly one bounded unit of work for the current user request and then stop after that delegated step is accepted, blocked, or rejected.
- In `booster` mode, the orchestrator may chain multiple delegated steps for the same feature, but only one phase-scoped delegated step at a time.
- Keep assigned phase and assigned subagent fixed within each delegated step.
- At most one delegated execution attempt is allowed per delegated step.
- Do not chain phases inside one delegated prompt or one specialist response.
- After each accepted delegated step in `booster` mode, recompute the earliest unresolved phase before deciding whether to continue.
- `booster` may continue only while the next phase is unambiguous, prerequisites are satisfied, and no blocker, rejection, or validation failure occurred.
- If a delegated step is `blocked` because transport failed, the authoritative payload is missing, or execution is otherwise invalid for continuation, stop the booster cycle immediately.
- After such a stop, only two follow-up paths are allowed: resume later in a fresh orchestrator run after transport is repaired, or explicitly exit orchestrator mode before starting any separate manual implementation pass.
- Do not blend a blocked booster cycle into transport repair, shared-skill patching, retry loops, or manual repo work while still presenting the run as orchestrated.
- Do not turn transport troubleshooting, smoke tests, background retries, or temp-path workarounds into extra work inside the same delegated step or booster cycle.

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

Phase-specific entry, blocked, rejected, owned-output, and artifact-marker rules live in the assigned specialist skill and the shared artifact marker reference.

Specialists share these thin common contracts:

- `./references/specialist-execution-contract.md`
- `./references/artifact-acceptance-markers.md`
- `./references/subagent-response-format.md`
- `./references/specialist-status-semantics.md`

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

### Delegated write rule

- For write-owning phases, the preferred success path is direct repo writes by the delegated specialist.
- When delegated transport cannot safely persist repo files but the specialist can still produce final artifact content, the specialist should return those files in the approved `Artifacts` payload section.
- The orchestrator then materializes those repo-relative artifact payloads locally before marker validation, acceptance, and any booster continuation decision.
- Do not classify a write-owning delegated step as blocked solely because direct delegated writes failed when valid artifact payloads are already present in the response.

### Efficiency rules

- Prefer direct fixed paths over recursive search. Search only when a required direct path is missing or unreadable.
- Do not preload multiple specialist skills “just in case”.
- Do not reopen shared reference files when the mapped specialist already loaded the shared shortcut and no conflict is present.
- Treat `bash ./scripts/validate_delegated_run.sh` as the default single acceptance entry point. Do not separately rerun schema validation, marker validation, and snapshot refresh on the happy path.
- Expect a compact delegated schema. Read the delegated `response_file` directly when validator output is insufficient and use the single `Result` section rather than expecting many micro-fields.
- For write-owning phases, treat response-embedded `Artifacts` payloads as the preferred fallback when delegated transport can read but cannot safely persist repo files.
- Prefer the delegated manifest as the source of response and log paths. Do not rediscover run artifacts with workspace globbing.
- Keep progress narration decision-focused. Summarize the route, delegated phase, validation result, and next bounded step rather than narrating every file read.
- In `booster` mode, reuse the smallest stable context between accepted steps: refreshed snapshot, validated markers, the next phase prompt, and the next specialist skill.
- In `booster` mode, do not preload all later-phase specialist skills at once; load each next specialist only after the prior step is accepted.

## Validation policy

- Every delegated response must match the approved schema in:
  - `./references/subagent-response-format.md`
- Delegated status interpretation must remain consistent with:
  - `./references/specialist-status-semantics.md`
- Every delegated response must be validated with:
  - `bash ./scripts/validate_subagent_response.sh`
- When phase acceptance is claimed through markerized workflow artifacts, validate them with:
  - `bash ./scripts/validate_artifact_markers.sh specs/<feature>`
- Use `--require-markers` after a phase-owned update that is expected to create or preserve markerized artifacts.
- Always invoke the validator as `bash <script>`.
- One repair pass is allowed only for format-only defects after an authoritative delegated payload exists.
- If a delegated attempt fails to produce an authoritative payload, classify that delegated step as `blocked` and stop rather than debugging transport inside the same step.
- A blocked transport step does not authorize shared-tool patching, workaround retries, or manual feature work inside the same orchestrator cycle.
- Semantic violations must be rejected, not normalized.
- If an invalid response cannot be safely repaired, replace it with a controlled failure record using:
  - `bash ./scripts/print_subagent_response_schema.sh`

### Snapshot refresh rule

- After accepting a schema-valid inspection result or a marker-validated phase-owned update, refresh the routing snapshot for that feature and verify the written file by rereading it immediately.
- Use:
  - `bash ./scripts/validate_delegated_run.sh`
- Do not refresh the routing snapshot from terminal chatter or raw logs.
- Do not reuse a routing snapshot when the feature fingerprint changed.
- In `booster` mode, treat each accepted step as a new snapshot decision point before continuing.

Delegated execution references:

- lifecycle sequence: `./references/subagent-lifecycle.md`
- delegated prompt and authority checks: `./references/subagent-reinjection-contract.md`
- fallback and repair: `./references/orchestrator-fallback.md`
- external Codex CLI transport skill: `../codex-cli-subagent-transport/SKILL.md`
- anti-pattern guardrails: `./references/orchestrator-anti-patterns.md`
- execution modes: `./references/orchestrator-modes.md`

## Transport contract

### Native subagent selection contract

- When using native subagent execution, invoke the exact mapped specialist for `Assigned-Subagent`.
- Do not substitute a generic exploration, search, or Q&A agent for the mapped specialist.
- A read-only native agent is invalid for a write-owning phase.
- If the mapped specialist is not registered as a native agent, or the available native agent cannot perform the phase-owned file updates in scope, treat native subagent execution as unavailable for that run and use the external transport skill instead.
- Native delegation must preserve the assigned specialist identity in both agent selection and delegated prompt content.

### Write-owning phases

Treat these phases as write-owning whenever their normal owned outputs are in scope:

- `specification` via `spec-analyst`
- `planning` via `spec-planner`
- `task decomposition` via `spec-tasker`
- `implementation` via `spec-implementer`
- `drift check` via `spec-drift-check` when `drift.md` updates are in scope
- `handoff` via `spec-handoff` when `handoff.md` updates are in scope

Read-only agents may inspect these phases only for separate non-owning inspection assignments. They must not be used for the delegated specialist run that is expected to write the owned artifacts.

- Use native subagent execution when available.
- If native subagent execution is unavailable, use the external Codex CLI transport skill in:
  - `../codex-cli-subagent-transport/SKILL.md`
- Prefer:
  - `bash ../codex-cli-subagent-transport/scripts/run_codex_cli_subagent.sh`
  over ad hoc raw `codex exec` invocations when the orchestrator must later read delegated run artifacts.
- When installed bundle assets live under `~/.codex/skills/...`, prefer direct path resolution with:
  - `bash ~/.codex/skills/spec-orchestrator/scripts/resolve_bundle_paths.sh --specialist <assigned-subagent>`
  before any recursive search.
- Follow the manifest-based run contract in:
  - `../codex-cli-subagent-transport/references/manifest-based-run-contract.md`
- Materialize delegated run artifacts in a repo-local run directory rather than `/tmp`.
- Treat delegated `manifest.json` or `manifest.env` as the authoritative locator for `response_file` and `exec_log`.
- Treat delegated `response_file` as authoritative output.
- Treat execution logs as diagnostics only.
- Prefer fixed known bundle paths under `~/.codex/skills/spec-orchestrator/` and `~/.codex/skills/codex-cli-subagent-transport/` before recursive workspace search when locating skills, validators, and transport assets.
- Do not infer accepted phase output from terminal chatter.
- Do not use environment warnings, unrelated skill-load failures, or shell-policy denials as feature-state evidence.

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
- blocked transport or invalid delegated execution would require repair work before the next specialist step can run
- `booster` would need to guess the next phase, skip a required phase, or continue after any non-`completed` delegated status
- `booster` reaches a valid terminal state such as accepted handoff or no further unresolved phase with satisfied workflow requirements

## Explicit orchestrator exit rule

- If the operator chooses not to resume later after a blocked transport stop, the orchestrator may end its own mode cycle and explicitly declare that orchestration has stopped.
- Any later manual implementation pass must be labeled as a separate execution model, not as continued `standard` or `booster` orchestration.
- Manual work that starts after orchestrator exit must not be counted as an accepted delegated step, must not be written into the routing snapshot as if a specialist completed it, and must not be described as preserving booster continuity.
- If the user later wants workflow orchestration again, start a fresh orchestrator run from current validated artifacts, marker checks, and any reusable routing snapshot.

## Continuity rule

- Record only minimal durable coordination notes when continuity is needed.
- Prefer existing workflow artifacts and their acceptance markers over chat history when resuming.
- Treat a later resume after blocked transport as a fresh orchestrator run, not as hidden continuation inside the old booster cycle.
- When markerized artifacts are used as the basis for routing or continuation, require them to pass `bash ./scripts/validate_artifact_markers.sh` before treating them as authoritative.
- Treat formal acceptance as an artifact marker decision, not just a prior summary statement.
- Treat pre-delegation observations and prior summaries as non-authoritative when they conflict with validated markers or the current schema-valid inspection result.
- Repo-local routing snapshots are allowed as minimal durable coordination notes.
- They must never override validated artifact markers.
- They are reusable only while the referenced feature fingerprint still matches.
- They must not be refreshed from blocked transport, missing response payloads, or manual work that happened after explicit orchestrator exit.
- Handoff packaging belongs to `spec-handoff`, not the orchestrator by default.
- `booster` may use the same continuity artifacts between steps, but each continuation decision must still come from current validated state rather than stale chat intent.
