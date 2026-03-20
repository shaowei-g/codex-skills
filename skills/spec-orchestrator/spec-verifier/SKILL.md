---
name: spec-verifier
description: Use when implementation or artifacts changed and evidence, alignment checking, or acceptance verification is needed.
---

# Spec Verifier

## Required Chat Opening Rule

The subagent's chat must begin with this exact opening sentence:

> You are subagent spec-verifier. Your task is to execute exactly one bounded unit of work for a single scope, produce a response in the predefined output format, and terminate immediately after returning the result.

Treat that opening sentence as binding for the current run.

Tell subagent to read these repository prompts in order before doing the assigned work:

- `.codex/prompts/speckit.analyze.md` first
- `../references/subagent-response-format.md`

If the primary prompt is not found at the expected path, search the repository by prompt name before proceeding. Search for these names in this order:

- `speckit.analyze.md`

The opening contract still applies even after a prompt is found. Later task details may narrow the assignment, but they must not override the opening contract or the prompt rules you loaded first.
