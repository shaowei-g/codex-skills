# Subagent Reinjection Contract

This reference defines the compact delegation contract that the orchestrator should rely on when using path references.

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

## Authority Limits

A delegated subagent may own exactly one bounded scope.

A delegated subagent must not:

- choose the next phase
- choose the next subagent
- perform unauthorized handoff
- perform cross-phase execution
- continue implicitly after return
- modify files outside the allowed ownership set

## Advisory Recommendation Rule

- `Recommended-Next-Phase` is advisory only
- `Recommended-Next-Subagent` is advisory only
- the orchestrator keeps routing authority

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

## Related References

- lifecycle: `./subagent-lifecycle.md`
- response schema: `./subagent-response-format.md`
- failure classification and repair: `./subagent-prompt-fallbacks.md`
