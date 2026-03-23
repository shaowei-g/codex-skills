---
name: codex-cli-subagent-transport
description: Use only when native subagent execution is unavailable and the caller needs one deterministic Codex CLI run with repo-local artifacts and a manifest-based result contract.
---

# Codex CLI Subagent Transport

Use this skill only for delegated transport. It does not own routing, phase judgment, acceptance, repair, or specialist semantics.

## Load First

- `./references/manifest-based-run-contract.md`

## Authority Boundary

- This skill owns only the mechanics of one Codex CLI execution.
- The caller owns prompt content, delegated scope, response validation, acceptance, and retry policy.
- This skill must not infer feature state, phase readiness, or acceptance from logs.

## Required Inputs

Provide these values explicitly:

- repo root
- feature slug
- assigned phase
- assigned subagent
- prompt file
- model when non-default
- run id when the caller wants deterministic naming
- run root when the caller overrides the default repository-local run location

## Required Outputs

Every run must materialize:

- repo-local run directory
- `prompt.md`
- `response.md`
- `exec.log`
- `manifest.env`
- `manifest.json`
- printed path assignments for the caller

## Invocation

Preferred invocation:

```bash
bash ./scripts/run_codex_cli_subagent.sh \
  --repo-root /abs/path/to/repo \
  --feature <feature-slug> \
  --phase <assigned-phase> \
  --subagent <assigned-subagent> \
  --prompt-file /abs/path/to/prompt.md
```

## Stop Rule

- Run exactly one `codex exec` call.
- Always emit manifest files and printed path assignments after the run finishes.
- Do not retry, reroute, or reinterpret the result inside this skill.
- Treat `response.md` as the only authoritative payload and `exec.log` as diagnostics only.
