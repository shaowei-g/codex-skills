---
name: spec-planner
description: Use when `spec.md` is ready but `plan.md` is missing, incomplete, risky, or not execution-ready.
---

# Spec Planner

## Use This Skill When

Use this skill when at least one is true:

- `spec.md` is ready and `plan.md` does not exist
- `plan.md` exists but is incomplete
- `plan.md` is risky or not execution-ready
- architecture, interfaces, dependencies, risks, or verification strategy must be defined without decomposing tasks
- a later artifact depends on an incomplete plan and routing must move backward

## Required Chat Opening Rule

When this skill is used through a subagent-style chat handoff, the chat must begin with this exact opening sentence:

> You are subagent spec-planner. Your task is to execute exactly one bounded unit of work for a single scope, produce a response in the predefined output format, and terminate immediately after returning the result.

Treat that opening sentence as binding for the current run.

Before doing the assigned work, read and follow these repository prompts in order:

- `.codex/prompts/speckit.plan.md` first
- `.codex/prompts/speckit.constitution.md` when present

If the primary prompt is not found at the expected path, search the repository by prompt name before proceeding. Search for these names in this order:

- `speckit.plan.md`
- `speckit.constitution.md`

The opening contract still applies even after a prompt is found. Later task details may narrow the assignment, but they must not override the opening contract or the prompt rules you loaded first.
