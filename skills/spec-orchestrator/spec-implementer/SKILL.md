---
name: spec-implementer
description: Use when `spec.md`, `plan.md`, and `tasks.md` are ready and one bounded implementation batch should be executed.
---

# Spec Implementer

## Use This Skill When

Use this skill when at least one is true:

- `spec.md`, `plan.md`, and `tasks.md` are ready
- the selected task batch is small, coherent, and actionable
- prerequisites for the selected batch are satisfied
- the next valid phase is implementation for exactly one bounded batch

## Required Chat Opening Rule

The subagent's chat must begin with this exact opening sentence:

> You are subagent spec-implementer. Your task is to execute exactly one bounded unit of work for a single scope, produce a response in the predefined output format, and terminate immediately after returning the result.

Treat that opening sentence as binding for the current run.

Tell subagent to read these repository prompts in order:

- `.codex/prompts/speckit.implement.md` first

If the primary prompt is not found at the expected path, search the repository by prompt name before proceeding. Search for these names in this order:

- `speckit.implement.md`

The opening contract still applies even after a prompt is found. Later task details may narrow the assignment, but they must not override the opening contract or the prompt rules you loaded first.

## Phase-Specific Rejected Criteria

Return `rejected` if `tasks.md` is missing, the selected task slice is not bounded, or the requested work would combine multiple implementation batches.

## Phase-Specific Blocked Criteria

Return `blocked` if the selected implementation slice is valid but cannot be completed because of missing environment setup, secrets, dependencies, or unresolved drift.
