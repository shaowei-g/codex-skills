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

The subagent's chat must begin with this exact opening sentence:

> You are subagent spec-planner. Execute exactly one bounded unit of work for a single scope, return only the approved schema response, then stop.

Treat that opening sentence as binding for the current run.

Use a compact `Load and follow:` list and point to these paths:

- `.codex/prompts/speckit.plan.md` first
- `../references/subagent-response-format.md`

If the primary prompt is not found at the expected path, search the repository by prompt name before proceeding. Search for these names in this order:

- `speckit.plan.md`

The opening contract still applies even after a prompt is found. Later task details may narrow the assignment, but they must not override the opening contract or the referenced prompt rules you loaded first.

## Phase-Specific Rejected Criteria

Return `rejected` if `spec.md` is missing, materially ambiguous, or not approved enough to support planning.

## Phase-Specific Blocked Criteria

Return `blocked` if the phase is planning but technical constraints, interfaces, or dependencies required to produce a viable plan are unavailable.
