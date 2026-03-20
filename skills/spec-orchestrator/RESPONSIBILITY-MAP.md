# Bundle Responsibility Map

This file defines the intended responsibility split for the streamlined `spec-orchestrator` bundle.

## Design Goal

Keep the main orchestrator prompt as a thin policy shell:

- routing authority
- gate policy
- validation policy
- stop conditions
- transport contract pointers

Everything else should live in one canonical reference or the owning specialist skill.

## File Responsibility Table

| File | Primary responsibility | Keep here | Move out / avoid duplicating |
| --- | --- | --- | --- |
| `SKILL.md` | Orchestrator authority and routing shell | routing authority, feature gate, earliest-unresolved-phase rule, validation acceptance, stop conditions, transport pointer | phase details, full lifecycle prose, response schema details, repeated prompt lookup chain |
| `references/codex-prompt-mapping.md` | Repository prompt resolution | phase → primary prompt mapping, lookup order, constitution/clarify loading rules | blocked/rejected taxonomy, lifecycle, validator policy |
| `references/subagent-lifecycle.md` | Execution sequence for one delegated run | create → inject → load → gate → execute → persist → return → stop | prompt lookup details already in mapping, validator taxonomy already elsewhere |
| `references/subagent-reinjection-contract.md` | Compact delegation contract | allowed authority, required delegated fields, ownership boundaries, self-check contract, violation taxonomy | full response schema, prompt lookup chain, transport troubleshooting prose |
| `references/subagent-prompt-fallbacks.md` | Failure classification and fallback | local fallback rule, blocked vs rejected policy, transport fallback, reconstruction repair | prompt mapping details, lifecycle repetition, schema repetition |
| `references/subagent-response-format.md` | Canonical response schema | headings, enums, field rules, machine validation semantics | lifecycle, routing, fallback rules |
| `spec-viewer/SKILL.md` | Inspection-phase specialist behavior | inspection purpose, read order, phase-local blocked/rejected criteria, owned outputs | shared lifecycle contract, shared schema restatement |
| `spec-analyst/SKILL.md` | Specification-phase specialist behavior | spec-local purpose, entry signals, blocked/rejected criteria, owned outputs | shared lifecycle contract, prompt fallback taxonomy |
| `spec-planner/SKILL.md` | Planning-phase specialist behavior | plan-local purpose, entry signals, blocked/rejected criteria, owned outputs | shared lifecycle contract, shared validator prose |
| `spec-tasker/SKILL.md` | Task decomposition specialist behavior | tasks-local purpose, entry signals, blocked/rejected criteria, owned outputs | shared lifecycle contract, schema repetition |
| `spec-implementer/SKILL.md` | Implementation specialist behavior | implementation entry signals, bounded-batch rule, phase-local blocked/rejected criteria | shared lifecycle contract, prompt lookup chain duplication |
| `spec-verifier/SKILL.md` | Verification specialist behavior | evidence and alignment review behavior, phase-local blocked/rejected criteria | shared lifecycle contract, schema repetition |
| `spec-drift-check/SKILL.md` | Drift-assessment specialist behavior | drift-specific procedure, artifact/code alignment decision rules | repeated transport or lifecycle rules |
| `spec-handoff/SKILL.md` | Continuity packaging specialist behavior | handoff packaging purpose, artifact read set, helper scripts, phase-local blocked/rejected criteria | shared response schema duplication, orchestrator routing policy |

## Canonical Ownership Rules

- If a rule applies to every delegated run, prefer a shared reference over repeating it in each specialist skill.
- If a rule is about one phase only, keep it in that specialist skill.
- If a rule is about the wire format, keep it only in `references/subagent-response-format.md`.
- If a rule is about prompt path resolution, keep it only in `references/codex-prompt-mapping.md`.
- If a rule is about blocked vs rejected vs repair behavior, keep it only in `references/subagent-prompt-fallbacks.md`.
- If a rule is about delegation authority and self-check semantics, keep it only in `references/subagent-reinjection-contract.md`.

## Maintenance Rule

When editing the bundle:

1. update the canonical owner first
2. replace duplicates with path references
3. keep the main orchestrator file short enough to scan quickly
4. prefer path references over pasting the full contract into prompts
