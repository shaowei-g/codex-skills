# Orchestrator Fallback and Repair

This reference defines the fallback, transport, and repair rules that belong to `spec-orchestrator` during delegated execution and result handling.

## Local Fallback Rule

After following `./codex-prompt-mapping.md`:

- use the assigned specialist skill as the local phase fallback
- do not substitute a different phase prompt
- do not use fallback to justify cross-phase work

## Delegation Transport Rule

If native subagent support is unavailable, use the external transport skill in:

- `../../codex-cli-subagent-transport/SKILL.md`

Follow its manifest-based contract in:

- `../../codex-cli-subagent-transport/references/manifest-based-run-contract.md`

Transport interpretation rules:

- invoke the external transport wrapper rather than embedding raw `codex exec` transport logic in the orchestrator
- when the available native agent is generic or read-only for a write-owning phase, classify native delegation as unavailable and fall back to the external transport skill instead of attempting the mismatched agent

- prefer `bash ../../codex-cli-subagent-transport/scripts/run_codex_cli_subagent.sh` over ad hoc raw `codex exec` invocations
- materialize delegated run artifacts in a repo-local run directory rather than `/tmp`
- use `manifest.json` or `manifest.env` as the authoritative locator for run artifacts
- `response_file` is the authoritative delegated output
- `exec_log` is diagnostic only
- validate `response_file` with `bash ./scripts/validate_subagent_response.sh`
- when `response_file` contains approved `Artifacts` payloads, materialize them via `bash ./scripts/materialize_response_artifacts.sh` instead of treating missing delegated repo writes as an immediate blocker
- one delegated step gets at most one execution attempt
- if that attempt fails or `response_file` is missing, classify the current step as `blocked` and stop the current mode cycle
- `booster` may start a later delegated step only after the current step produced an authoritative accepted payload and the next phase is re-derived from current validated state
- do not perform in-step smoke tests, background retries, alternate temp-path experiments, workspace-glob discovery, or workaround loops after the delegated attempt fails
- do not patch installed shared skills, `~/.codex/skills/...` transport scripts, or other global tooling as part of the bounded feature run

## Post-Block Transition Rule

When a delegated step is blocked because transport failed or no authoritative payload exists, only these next actions are allowed:

- **resume later**: end the current orchestrator cycle, repair transport outside the feature run, and start a fresh orchestrator run later
- **explicit orchestrator exit**: end the current orchestrator cycle first, then begin any manual implementation pass as a separate execution model

Forbidden transitions after a blocked transport step:

- retrying the same delegated step inside the same cycle
- patching shared skills or transport scripts and then continuing as if the blocked cycle were still valid
- switching directly into manual repo edits while still describing the work as `standard` or `booster` orchestration

## Diagnostic Isolation Rule

Treat these as diagnostics only, never as feature-state evidence:

- CLI customization warnings
- unrelated skill-load failures
- shell-policy denials
- temp-directory visibility quirks
- workspace search limitations for non-repo paths
- permission or environment limitations that belong to the runtime rather than the feature

Allowed use of diagnostics:

- explain why the delegated run is `blocked`
- support transport troubleshooting outside the bounded feature run
- support reconstruction only after an authoritative delegated payload or durable repository evidence already exists
- support deciding whether to resume later or explicitly exit orchestration

Forbidden use of diagnostics:

- inferring feature readiness, drift, or acceptance
- replacing the missing delegated inspection result
- justifying a second delegated attempt inside the same run
- hiding an orchestrator exit boundary and continuing with manual feature work as though the blocked cycle were still authoritative

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
- execution logs, but only as support for already-established repository evidence

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
- external Codex CLI transport skill: `../../codex-cli-subagent-transport/references/manifest-based-run-contract.md`
- anti-pattern guardrails: `./orchestrator-anti-patterns.md`
