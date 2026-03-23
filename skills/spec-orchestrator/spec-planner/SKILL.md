---
name: spec-planner
description: Use when `spec.md` is ready but `plan.md` is missing, incomplete, risky, or not execution-ready.
---

# Spec Planner

Use this skill when planning is the current phase for one feature.

## Shared Contracts

Load this shared shortcut first:

- `../references/shared-specialist-contract.md`

Open the deeper canonical shared references only when the shortcut is insufficient for the current situation.

## Purpose

Use this skill when at least one is true:

- `spec.md` is ready and `plan.md` does not exist
- `plan.md` exists but is incomplete or risky
- architecture, interfaces, dependencies, risks, or verification strategy must be defined without decomposing tasks
- a later artifact depends on an incomplete plan and routing must move backward

## Read Order

- `.codex/prompts/speckit.plan.md` first
- `.codex/prompts/speckit.constitution.md` if present
- `specs/<feature>/spec.md`
- `specs/<feature>/plan.md` if present
- related implementation context only when needed to keep the plan realistic

## Owned Outputs

- `plan.md` with markerized front matter when safe to add or preserve
- plan-level architecture and dependency decisions
- implementation-ready approach notes for the assigned feature

## Phase-Specific Rejected Criteria

Return `rejected` if `spec.md` is missing, materially ambiguous, or not ready enough to support planning.

## Phase-Specific Blocked Criteria

Return `blocked` if technical constraints, interfaces, or dependencies required to produce a viable plan are unavailable.
