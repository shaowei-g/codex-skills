---
name: codex-cli-subagent-transport
description: Use when a workflow needs Codex CLI to act as a subagent transport because native subagent support is unavailable. Defines the only recommended Codex delegation transport using gpt-5.4-mini with low reasoning effort, prompt temp files, authoritative response files, and diagnostic exec logs.
---

# Codex CLI Subagent Transport

Use this skill only when a workflow must delegate bounded subagent work but the current runtime does not support native subagents.

## Purpose

This skill defines the standard Codex CLI transport for delegated subagent work.

It exists to keep delegation transport rules out of individual workflow skills.

## Required model settings

- model: `gpt-5.4-mini`
- reasoning effort: `low`

## Standard transport

Use this exact transport shape:

```bash
cat > "$prompt_file" <<'EOF'
<delegation prompt>
EOF

codex exec --model gpt-5.4-mini -c model_reasoning_effort="low" -o "$response_file" - < "$prompt_file" > "$exec_log" 2>&1
```

## Transport rules

- write the full delegated prompt into `prompt_file`
- read only `response_file` as the authoritative delegated result
- treat `exec_log` as diagnostics only
- do not infer delegated output from terminal chatter or execution logs
- if the workflow uses a validator, validate only `response_file`
- if the CLI command fails or `response_file` is missing, classify the delegated run as `blocked`

## Authoritative output rule

`response_file` is the only authoritative result of the delegated run.

`exec_log` may be used for debugging transport failures, but it must never be treated as the delegated answer.

## Workflow integration rule

When another workflow skill references this skill, that workflow must still enforce its own:

- scope limits
- schema validation
- repair-pass limits
- blocked and rejected classification
- reject-or-replace behavior

This skill defines transport only. It does not define the delegated task contract.

## Do Not Use This Skill For

- replacing native subagents when native subagents are available
- defining phase-specific blocked or rejected rules
- interpreting delegated output
- bypassing workflow-level validators