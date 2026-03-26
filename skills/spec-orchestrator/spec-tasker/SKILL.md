---
name: spec-tasker
description: Use when `plan.md` is ready but `tasks.md` is missing, vague, oversized, unordered, or not verifiable.
---

# Spec Tasker

Use this skill when task decomposition is the current phase for one feature.

## Shared Contracts

Load this shared shortcut first:

- `../references/shared-specialist-contract.md`

Open the deeper canonical shared references only when the shortcut is insufficient for the current situation.

## Purpose

Use this skill when at least one is true:

- `spec.md` and `plan.md` are ready and `tasks.md` does not exist
- `tasks.md` exists but tasks are vague, oversized, or not independently verifiable
- task ordering or dependencies are unclear
- implementation cannot proceed safely because the work is not decomposed into bounded batches

## Read Order

- `.codex/prompts/speckit.tasks.md` first
- `.codex/prompts/speckit.constitution.md` if present
- `specs/<feature>/spec.md`
- `specs/<feature>/plan.md`
- `specs/<feature>/tasks.md` if present

## Owned Outputs

- `tasks.md`
- ordered bounded task batches
- dependency and verification notes required for safe implementation

## Phase-Specific Rejected Criteria

Return `rejected` if `plan.md` is missing or not execution-ready.

## Phase-Specific Blocked Criteria

Return `blocked` if the plan exists but cannot be decomposed into verifiable bounded tasks without unresolved architectural decisions.
