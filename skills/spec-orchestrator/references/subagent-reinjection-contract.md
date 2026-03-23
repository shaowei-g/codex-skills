# Subagent Reinjection Contract

This reference defines the compact delegated prompt contract and the semantic authority checks that `spec-orchestrator` should enforce.

Execution order lives in `./subagent-lifecycle.md`.

## Compact Delegation Rule

- prefer required fields plus path references
- reference shared contracts instead of restating them inline
- restate only run-specific values that referenced files cannot infer
- keep delegated prompts short enough to scan quickly
- expand the full checklist only when the runtime cannot reliably load referenced files

## Required Delegated Fields

Every delegated run should make these values explicit:

- Feature-Slug
- Artifact-Directory
- Earliest-Unresolved-Phase
- Assigned-Phase
- Assigned-Subagent
- Scope
- Specialist-Skill
- Repository-Prompt
- Allowed-Ownership
- Forbidden-Artifact-Updates
- Response-Schema
- Response-Validator
- Stop-After-Return

When the assigned phase is `inspection`, the delegated scope should ask only for a truthful state report and advisory routing recommendation. It must not embed an already-decided workflow conclusion as if inspection were merely confirmation.
When inspection includes advisory recommendation fields, the delegated subagent should still keep `chose_next_phase = false` and `chose_next_subagent = false` because the recommendations do not exercise routing authority.

## Authority and Ownership Checks

A delegated subagent must remain within the assigned feature, phase, scope, and ownership set.

A delegated subagent must not:

- choose the next phase
- use a generic read-only exploration or Q&A agent as a substitute for a write-owning specialist
- accept a write-owning assignment when it cannot modify the owned artifacts in scope
- choose the next subagent
- perform unauthorized handoff
- perform cross-phase execution
- continue implicitly after return
- modify files outside the allowed ownership set

The orchestrator must not:

- bypass the external transport skill and inline ad hoc raw `codex exec` collection logic when deterministic manifest-based artifacts are required
- treat a generic read-only native agent as a valid implementation of `Assigned-Subagent` for a write-owning phase

- present preliminary artifact observations as authoritative phase acceptance when validated markers or the delegated inspection result are still pending
- substitute environment diagnostics for the missing specialist result

## Advisory Recommendation Rule

- `Recommended-Next-Phase` is advisory only
- `Recommended-Next-Subagent` is advisory only
- the orchestrator keeps routing authority
- for inspection runs, authoritative routing still depends on the schema-valid inspection result or validated artifact markers

## Self-Check Contract

The delegated response must keep these values explicit:

- `one_bounded_scope = true`
- `assigned_phase_only = true`
- `chose_next_phase = false`
- `chose_next_subagent = false`
- `unauthorized_handoff = false`
- `outside_ownership_modification = false`
- `required_response_schema_used = true`
- `terminating_now = true`

## Violation Taxonomy

Use these labels when classifying semantic contract failures:

- `multi_scope_violation`
- `cross_phase_drift`
- `routing_override_attempt`
- `unauthorized_handoff`
- `ownership_violation`
- `forbidden_artifact_update`
- `undeclared_file_change`
- `advisory_as_authority`
- `prerequisite_bypass`
- `premature_state_conclusion`
- `diagnostic_as_feature_evidence`

## Related References

- lifecycle sequence: `./subagent-lifecycle.md`
- artifact acceptance: `./artifact-acceptance-markers.md`
- fallback and repair: `./orchestrator-fallback.md`
- external Codex CLI transport skill: `../../codex-cli-subagent-transport/references/manifest-based-run-contract.md`
- anti-pattern guardrails: `./orchestrator-anti-patterns.md`
- response schema: `./subagent-response-format.md`

## Artifact Marker Reference

When a delegated result includes phase-owned artifact updates that are intended to support formal phase acceptance or continuation, the orchestrator should validate the artifact markers with the artifact marker validator before accepting the run as authoritative.

- `bash ./scripts/validate_artifact_markers.sh specs/<feature>`
- use `--require-markers` when the updated artifacts are expected to carry front matter markers
