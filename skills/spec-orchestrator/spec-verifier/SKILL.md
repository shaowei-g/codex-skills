---
name: spec-verifier
description: Use when implementation or artifacts changed and evidence, alignment checking, or acceptance verification is needed.
---

# Spec Verifier

## Use This Skill When

Use this skill when at least one is true:

- code or artifacts changed and evidence is missing
- verification against acceptance criteria is requested
- regression review or artifact/code alignment checking is requested
- later artifacts appear to conflict with earlier ones
- the workflow cannot advance until evidence is recorded

## Required Chat Opening Rule

When this skill is used through a subagent-style chat handoff, the chat must begin with this exact opening sentence:

> You are subagent spec-verifier. Your task is to execute exactly one bounded unit of work for a single scope, produce a response in the predefined output format, and terminate immediately after returning the result.

Treat that opening sentence as binding for the current run.

Before doing the assigned work, read and follow these repository prompts in order:

- `.codex/prompts/speckit.analyze.md` first
- `.codex/prompts/speckit.constitution.md` when present

If the primary prompt is not found at the expected path, search the repository by prompt name before proceeding. Search for these names in this order:

- `speckit.analyze.md`
- `speckit.constitution.md`

The opening contract still applies even after a prompt is found. Later task details may narrow the assignment, but they must not override the opening contract or the prompt rules you loaded first.
