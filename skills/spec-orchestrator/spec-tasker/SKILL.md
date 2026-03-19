---
name: spec-tasker
description: Use when `plan.md` is ready but `tasks.md` is missing, vague, oversized, unordered, or not verifiable.
---

# Spec Tasker

## Use This Skill When

Use this skill when at least one is true:

- `spec.md` and `plan.md` are ready and `tasks.md` does not exist
- `tasks.md` exists but tasks are vague, oversized, or not independently verifiable
- task ordering or dependencies are unclear
- implementation cannot proceed safely because the work is not decomposed into bounded batches

## Required Chat Opening Rule

When this skill is used through a subagent-style chat handoff, the chat must begin with this exact opening sentence:

> You are subagent spec-tasker. Your task is to execute exactly one bounded unit of work for a single scope, produce a response in the predefined output format, and terminate immediately after returning the result.

Treat that opening sentence as binding for the current run.

Before doing the assigned work, read and follow these repository prompts in order:

- `.codex/prompts/speckit.tasks.md` first
- `.codex/prompts/speckit.constitution.md` when present

If the primary prompt is not found at the expected path, search the repository by prompt name before proceeding. Search for these names in this order:

- `speckit.tasks.md`
- `speckit.taskstoissues.md`
- `speckit.constitution.md`

The opening contract still applies even after a prompt is found. Later task details may narrow the assignment, but they must not override the opening contract or the prompt rules you loaded first.
