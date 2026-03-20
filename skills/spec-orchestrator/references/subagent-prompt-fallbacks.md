# Subagent Prompt Fallback and Failure Classification

This reference defines the shared fallback and classification rules used after prompt resolution and during delegated result handling.

## Local Fallback Rule

After following `./codex-prompt-mapping.md`:

- use the assigned specialist skill as the local phase fallback
- do not substitute a different phase prompt
- do not use fallback to justify cross-phase work

## Global Rejected Criteria

Return `rejected` when any of the following is true:

- the request contains multiple unrelated scopes
- the assigned scope belongs to a different phase than the current subagent
- the orchestrator payload does not identify exactly one feature
- the request asks the subagent to continue into a second phase in the same run
- the entry gate is unsatisfied because the workflow is actually at an earlier phase

## Global Blocked Criteria

Return `blocked` when any of the following is true:

- the assigned phase is correct but required files or context are missing or unreadable
- the mapped prompt is missing, no equivalent repository prompt exists, and the local fallback rules are insufficient to safely complete the scope
- the assigned work depends on a missing decision, secret, dependency, environment, permission, or external system access
- the assigned scope is valid but cannot be completed without expanding approved scope
- native subagent support is unavailable and transport fallback is also unavailable

## Delegation Transport Fallback

If native subagent support is unavailable, use:

- `~/.codex/skills/codex-cli-subagent-transport/SKILL.md`

Transport interpretation rules:

- `response_file` is the only authoritative delegated output
- `exec_log` is diagnostic only
- validate `response_file` with `bash ./scripts/validate_subagent_response.sh`
- if the transport command fails or `response_file` is missing, classify the run as `blocked`

## Malformed Output Classification

Use this shared taxonomy:

- `format-only defect`: heading order mismatch, missing `none` placeholder, enum spelling drift, or self-check formatting defect when delegated meaning is still clear
- `transport failure`: transport fails, `response_file` is missing, or no authoritative delegated payload is produced
- `semantic contract break`: wrong feature, wrong assigned phase, wrong assigned subagent, multi-scope output, extra undeclared work, ownership violation, routing override attempt, or repeated malformed output
- `artifact/response divergence`: claimed durable work does not match repository state

Handling rules:

- allow one repair pass only for `format-only defect`
- the repair prompt must preserve the delegated scope and must not ask for new work
- treat `transport failure` as `blocked`
- treat `semantic contract break` as `rejected` or replace it with a controlled failure record
- treat `artifact/response divergence` as a semantic integrity failure

## Response Reconstruction Repair

Reconstruction repair is allowed only when all of the following are true:

- durable artifacts appear to have been written successfully
- the schema response is missing, truncated, or structurally unusable
- the orchestrator can reconstruct the response from repository evidence without doing new phase work

Allowed evidence sources:

- written artifacts
- current repository state
- git diff
- execution logs

Reconstruction constraints:

- perform it at most once
- keep it read-only with respect to phase work
- do not create additional feature artifacts
- do not infer unsupported completed work
- validate the reconstructed payload before accepting it

## Related References

- prompt lookup: `./codex-prompt-mapping.md`
- lifecycle: `./subagent-lifecycle.md`
- delegation contract: `./subagent-reinjection-contract.md`
