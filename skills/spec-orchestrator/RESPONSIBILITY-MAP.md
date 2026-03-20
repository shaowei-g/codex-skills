# Bundle Responsibility Map

This file defines the intended responsibility split for the streamlined `spec-orchestrator` bundle.

## Design Goal

Keep the main orchestrator prompt as a thin policy shell:

- routing authority
- gate policy
- validation policy
- stop conditions
- transport contract pointers

Everything else should live in one canonical reference or the owning specialist skill. Specialists should load only a thin execution contract, shared artifact marker rules, shared status semantics, and the shared response schema, not orchestration mechanics.

## File Responsibility Table

| File | Primary responsibility | Keep here | Move out / avoid duplicating |
| --- | --- | --- | --- |
| `SKILL.md` | Orchestrator authority and routing shell | routing authority, feature gate, earliest-unresolved-phase rule, validation acceptance, stop conditions, transport pointer | phase details, full lifecycle prose, response schema details, repeated prompt lookup chain |
| `references/codex-prompt-mapping.md` | Repository prompt resolution | phase → primary prompt mapping, lookup order, constitution/clarify loading rules | blocked/rejected taxonomy, lifecycle, validator policy |
| `references/specialist-execution-contract.md` | Thin common contract for specialists | one bounded pass, no routing authority, advisory-only recommendations, schema-only return, stop rule | orchestration lifecycle, reinjection policy, transport fallback, validator repair flow, detailed status taxonomy |
| `references/artifact-acceptance-markers.md` | Canonical artifact acceptance and front matter contract | YAML marker fields, acceptance meaning, orchestrator-owned promotion, cross-artifact consistency checks | response schema details, transport fallback, phase-local expert judgment |
| `references/specialist-status-semantics.md` | Shared specialist status meanings | `completed` / `blocked` / `rejected` semantics, common status boundary examples | transport fallback, prompt mapping, reconstruction repair |
| `references/subagent-lifecycle.md` | Execution sequence for one delegated run | prepare assignment → inject → load prompt/local context → gate → execute → persist → collect response → stop | delegated field checklist, authority limits, self-check contract, violation taxonomy |
| `references/subagent-reinjection-contract.md` | Compact delegation and authority contract | required delegated fields, authority/ownership checks, advisory-only next-step rule, self-check contract, violation taxonomy | lifecycle step ordering, prompt lookup details, transport troubleshooting prose |
| `references/orchestrator-fallback.md` | Orchestrator-only fallback, transport, and repair | local fallback rule, transport fallback, malformed output classification, reconstruction repair | specialist status meanings, prompt mapping details, schema repetition |
| `references/subagent-prompt-fallbacks.md` | Compatibility shim only | pointer to the split references for older links | normative fallback or status rules |
| `references/subagent-response-format.md` | Canonical response schema | headings, enums, field rules, machine validation semantics | lifecycle, routing, fallback rules |
| `scripts/validate_artifact_markers.sh` + `scripts/validate_artifact_markers.py` | Canonical artifact marker validator | required marker fields, accepted-state checks, cross-artifact consistency checks, compatibility mode vs `--require-markers` strict mode | subagent response schema validation, routing policy, specialist phase judgment |
| `spec-viewer/SKILL.md` | Inspection-phase specialist behavior | inspection purpose, read order, phase-local blocked/rejected criteria, owned outputs | orchestration references, shared schema restatement |
| `spec-analyst/SKILL.md` | Specification-phase specialist behavior | spec-local purpose, entry signals, blocked/rejected criteria, owned outputs | orchestration references, prompt lookup duplication, fallback taxonomy |
| `spec-planner/SKILL.md` | Planning-phase specialist behavior | plan-local purpose, entry signals, blocked/rejected criteria, owned outputs | orchestration references, shared validator prose |
| `spec-tasker/SKILL.md` | Task decomposition specialist behavior | tasks-local purpose, entry signals, blocked/rejected criteria, owned outputs | orchestration references, schema repetition |
| `spec-implementer/SKILL.md` | Implementation specialist behavior | implementation entry signals, bounded-batch rule, phase-local blocked/rejected criteria | orchestration references, prompt lookup chain duplication |
| `spec-verifier/SKILL.md` | Verification specialist behavior | evidence and alignment review behavior, phase-local blocked/rejected criteria | orchestration references, schema repetition |
| `spec-drift-check/SKILL.md` | Drift-assessment specialist behavior | drift-specific procedure, artifact/code alignment decision rules | orchestration references, repeated transport rules |
| `spec-handoff/SKILL.md` | Continuity packaging specialist behavior | handoff packaging purpose, artifact read set, helper scripts, phase-local blocked/rejected criteria | shared response schema duplication, orchestrator routing policy, orchestration references |

## Canonical Ownership Rules

### `SKILL.md`
Keep only the orchestrator rules that must remain in the always-loaded shell:

- routing authority
- feature gate and earliest unresolved phase
- specialist binding table
- validator acceptance policy
- stop conditions
- pointers to the authoritative references

Do not repeat:

- specialist entry criteria
- full prompt lookup chain details
- response schema headings
- transport troubleshooting prose
- specialist status taxonomy
- artifact acceptance marker field definitions

### `references/specialist-execution-contract.md`
This file is for rules every specialist should always inherit:

- one bounded pass
- no routing authority
- advisory-only next-step recommendations
- schema-only return
- stop-after-return behavior

It should not explain:

- how delegated transport works
- how the orchestrator repairs malformed outputs
- repository prompt lookup
- detailed `blocked` / `rejected` semantics

### `references/artifact-acceptance-markers.md`
This file is the canonical source for formal artifact acceptance:

- required YAML front matter fields for markerized workflow artifacts
- orchestrator-owned acceptance promotion rules
- phase-local marker requirements for `spec.md`, `plan.md`, `tasks.md`, and `implementation-status.md`
- continuation and review interpretation order
- cross-artifact consistency checks

It should not define:

- response schema details
- transport fallback rules
- specialist phase-local expert judgment
- ad hoc acceptance summaries that are not persisted into artifacts

### `references/specialist-status-semantics.md`
This file is the shared source of truth for specialist status meanings:

- when to return `completed`
- when to return `blocked`
- when to return `rejected`
- how to distinguish phase mismatch from missing prerequisites

It should not define:

- transport fallback
- delegated-output repair
- response reconstruction
- validator invocation

### `references/orchestrator-fallback.md`
This file is the orchestrator-only source of truth for delegated-run fallback handling:

- local phase fallback after prompt lookup
- transport fallback
- malformed output classification
- reconstruction repair

It should not define:

- specialist phase-specific gates
- specialist `completed` / `blocked` / `rejected` semantics
- response schema structure

## Specialist Loading Rule

Each specialist `SKILL.md` should load only:

- `../references/specialist-execution-contract.md`
- `../references/artifact-acceptance-markers.md`
- `../references/specialist-status-semantics.md`
- `../references/subagent-response-format.md`

Each specialist should then define only:

- when that phase applies
- what it reads
- what it owns
- its phase-local blocked / rejected criteria

## Expected Benefits

This split reduces duplicated instruction load, keeps delegation mechanics centralized in orchestrator-owned references, and makes specialist skills read more like phase cards than mini-orchestrators.
