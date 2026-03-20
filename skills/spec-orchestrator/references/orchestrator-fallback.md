# Orchestrator Fallback and Repair

This reference defines the fallback, transport, and repair rules that belong to `spec-orchestrator` during delegated execution and result handling.

## Local Fallback Rule

After following `./codex-prompt-mapping.md`:

- use the assigned specialist skill as the local phase fallback
- do not substitute a different phase prompt
- do not use fallback to justify cross-phase work

## Delegation Transport Fallback

If native subagent support is unavailable, use:

- `~/.codex/skills/codex-cli-subagent-transport/SKILL.md`

Transport interpretation rules:

- `response_file` is the only authoritative delegated output
- `exec_log` is diagnostic only
- validate `response_file` with `bash ./scripts/validate_subagent_response.sh`
- if the transport command fails or `response_file` is missing, classify the run as `blocked`

## Malformed Output Classification

Use this taxonomy when classifying delegated result failures:

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
- response schema: `./subagent-response-format.md`
