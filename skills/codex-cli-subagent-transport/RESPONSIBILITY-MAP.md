# Codex CLI Subagent Transport Responsibility Map

## Design Goal

Keep Codex CLI transport separate from orchestration policy and specialist phase logic.

This skill owns only deterministic run-artifact creation and manifest-based result collection for one Codex CLI execution.

## File Responsibility Table

| File | Primary responsibility | Keep here | Avoid duplicating |
| --- | --- | --- | --- |
| `SKILL.md` | Thin transport shell | transport purpose, authority boundary, required inputs/outputs, stop rule | orchestration routing, phase judgment, response validation semantics |
| `references/manifest-based-run-contract.md` | Canonical repo-local run-artifact contract | run root, manifest files, authoritative payload rule, forbidden temp-path rediscovery | specialist semantics, acceptance logic, response schema rules |
| `scripts/run_codex_cli_subagent.sh` | Executable transport wrapper | one `codex exec`, manifest emission, deterministic repo-local paths | routing decisions, validator logic, retries policy |
