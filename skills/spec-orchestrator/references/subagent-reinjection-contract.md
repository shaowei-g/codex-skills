# Core Goal

- orchestrator authority
- prevent subagent drift
- multi-step delegation control
- validator-friendly
- weak-model robust

### subagent limits

- one bounded scope
- one assigned phase
- no next-phase decision
- no next-subagent decision
- no unauthorized handoff
- no cross-phase execution
- no implicit continuation
- terminate after return

### artifact modification rules

- explicit ownership set
- allowed artifact updates only
- forbidden artifact updates
- no out-of-scope file change
- declare all file changes

### status keywords

- `ok`
- `blocked`
- `rejected`

### blocked keywords

- missing prerequisite
- missing input
- missing artifact
- missing permission
- ambiguous ownership
- cannot proceed safely

### rejected keywords

- invalid scope
- multi-scope task
- phase violation
- routing violation
- ownership violation
- unauthorized handoff
- malformed schema
- contract breach

### reinjection layers

- delegation opening
- phase gate
- pre-return self-check

### delegation opening

- one scope
- one phase
- no routing authority
- no handoff authority
- schema-only return
- stop immediately

### phase gate

- Feature-Slug
- Earliest-Unresolved-Phase
- Assigned-Phase
- Assigned-Subagent
- Scope
- Allowed-Ownership
- Forbidden-Artifact-Updates
- Blocked-Handling
- Rejected-Handling

### response schema

- Status
- Feature-Slug
- Assigned-Phase
- Assigned-Subagent
- Scope
- Summary
- Files-Changed
- Files-Read
- Missing-Prerequisites
- Contract-Violations
- Recommended-Next-Phase
- Recommended-Next-Subagent
- Notes
- Self-Check

### self-check

- one_bounded_scope
- assigned_phase_only
- chose_next_phase = false
- chose_next_subagent = false
- unauthorized_handoff = false
- outside_ownership_modification = false
- required_response_schema_used = true
- terminating_now = true

### validator

- valid status
- single bounded scope
- assigned phase match
- assigned subagent match
- ownership compliance
- no forbidden updates
- no silent cross-phase work
- no silent handoff
- schema completeness
- self-check completeness
- advisory not treated as authority

### violation taxonomy

- format_violation
- missing_required_field
- invalid_status
- multi_scope_violation
- cross_phase_drift
- routing_override_attempt
- unauthorized_handoff
- ownership_violation
- forbidden_artifact_update
- undeclared_file_change
- self_check_incomplete
- self_check_noncompliant
- advisory_as_authority
- prerequisite_bypass

### recovery rules

- validate before continue
- discard invalid routing authority
- classify violation
- reroute from earliest unresolved phase
