---
name: spec-implementer
description: Use when `spec.md`, `plan.md`, and `tasks.md` are ready and one bounded implementation batch should be executed.
---

# Spec Implementer

Use this skill when implementation is the current phase for one feature.

## Shared Contracts

Load this shared shortcut first:

- `../references/shared-specialist-contract.md`

Open the deeper canonical shared references only when the shortcut is insufficient for the current situation.

## Purpose

Use this skill when at least one is true:

- `spec.md`, `plan.md`, and `tasks.md` are ready
- the selected task batch is small, coherent, and actionable
- prerequisites for the selected batch are satisfied
- the next valid phase is implementation for exactly one bounded batch

## Read Order

- `.codex/prompts/speckit.implement.md` first
- `.codex/prompts/speckit.constitution.md` if present
- `specs/<feature>/spec.md`
- `specs/<feature>/plan.md`
- `specs/<feature>/tasks.md`
- only the code and tests needed for the assigned batch

## Owned Outputs

- code and tests for one bounded implementation batch
- `specs/<feature>/implementation-status.md` updates for completed task IDs and verification commands when that record is in scope
- minimal required workflow artifact updates for the completed batch

## Phase-Specific Rejected Criteria

Return `rejected` if `tasks.md` is missing, the selected task slice is not bounded, or the requested work would combine multiple implementation batches.

## Phase-Specific Blocked Criteria

Return `blocked` if the selected implementation slice is valid but cannot be completed because of missing environment setup, secrets, dependencies, or unresolved drift.
