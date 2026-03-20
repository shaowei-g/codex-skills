# Subagent Prompt Fallback and Failure Classification

This reference defines the required prompt lookup fallback chain and the criteria for returning `blocked` or `rejected` when a prompt or prerequisite is missing.

## Prompt Lookup Fallback Chain

Every subagent must resolve prompt guidance in this order:

1. Load the phase-specific primary prompt defined in `./codex-prompt-mapping.md` from the repository root.
2. Also load `.codex/prompts/speckit.constitution.md` when present and apply it as a governing constraint.
3. Load `.codex/prompts/speckit.clarify.md` only when clarification is explicitly part of the assigned scope or the primary prompt requires clarification before proceeding.
4. If the mapped primary prompt is missing, search other prompt locations in the repository for an equivalent prompt for the same phase.
5. If no equivalent repository prompt is found, fall back to the local phase rules in the assigned agent or skill file.

A subagent may never use fallback to jump to a different phase prompt.
For example, an implementation subagent may not substitute a planning prompt.

## Global Rejected Criteria

Return `rejected` when any of the following is true:

- the request contains multiple unrelated scopes
- the assigned scope belongs to a different phase than the current subagent
- the orchestrator payload does not identify exactly one feature
- the task requires using a different phase prompt instead of the mapped phase prompt
- the request asks the subagent to continue into a second phase in the same run
- the entry gate for the phase is not satisfied because the workflow is actually at an earlier phase

## Global Blocked Criteria

Return `blocked` when any of the following is true:

- the assigned phase is correct but required repository files or context are missing or unreadable
- the mapped prompt is missing and repository prompt search yields no equivalent prompt, and the local fallback rules are insufficient to safely complete the scope
- the mapped prompt exists but is internally inconsistent with governing constraints and the conflict cannot be resolved from repository artifacts
- the assigned work depends on a missing user decision, missing secret, missing environment, missing dependency, or missing external system access
- the assigned scope is valid but cannot be completed without expanding spec-approved scope
- native subagent support is unavailable and Codex CLI fallback transport is also unavailable

## Delegation transport fallback

If native subagent support is unavailable, use the transport contract in `~/.codex/skills/codex-cli-subagent-transport/SKILL.md`.

Transport interpretation rules:

- `response_file` is the only authoritative delegated output
- `exec_log` is diagnostic only
- the orchestrator must validate `response_file` with `bash ./scripts/validate_subagent_response.sh`
- if the CLI command fails or `response_file` is missing, classify the run as `blocked` rather than improvising specialist work

## Phase-Specific Prompt Expectations

Phase-specific prompt order and phase-specific `blocked` / `rejected` criteria now live in each specialist skill file.

Use the relevant specialist skill as the source of truth for:

- preferred prompt chain for that phase
- phase-specific `blocked` criteria
- phase-specific `rejected` criteria
- any extra scope constraints that apply only to that specialist

This shared reference keeps only global fallback and global classification rules.

## Output Rule

When a subagent returns `blocked` or `rejected`, it must still complete the shared response format and make the reason explicit in `Blockers` or `Evidence` as appropriate.

## Malformed output classification

Use this validator failure taxonomy:

- `format-only defect`: heading order mismatch, missing `none` placeholder, enum spelling drift, or self-check formatting defect when the delegated meaning is still clear
- `transport failure`: Codex CLI or another delegation transport fails, `response_file` is missing, or no authoritative delegated payload is produced
- `semantic contract break`: wrong feature, wrong assigned phase, wrong assigned subagent, multi-scope output, extra undeclared work, ownership violation, routing override attempt, or a second failed repair pass
- `artifact/response divergence`: the delegated response claims files changed, artifacts updated, or durable work completed that do not match repository state or the actual outputs written in this run

Special case:

- if artifacts were successfully written but the schema response is missing or unusable, the orchestrator may attempt one read-only reconstruction repair before classifying the failure as unrecoverable

Handling rules:

- the orchestrator may allow one repair pass only for `format-only defect`
- the repair prompt must preserve the delegated scope and must not ask for new work
- `transport failure` must be classified as `blocked` unless a workflow-level replacement rule says otherwise
- `semantic contract break` must be rejected or replaced with a controlled failure record
- `artifact/response divergence` must be treated as a semantic integrity failure and rejected or replaced with a controlled failure record

## Response reconstruction repair

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
