---
name: spec-analyst
description: Use when `spec.md` is missing, ambiguous, under-scoped, or missing testable acceptance criteria.
---

# Spec Analyst

Use this skill when specification is the current phase for one feature.

## Shared Contracts

Load and follow these shared references first:

- `../references/specialist-execution-contract.md`
- `../references/subagent-response-format.md`
- `../references/specialist-status-semantics.md`

## Purpose

Use this skill when at least one is true:

- `spec.md` is missing
- `spec.md` is ambiguous, incomplete, or stale
- acceptance criteria are not testable
- scope boundaries are unclear
- a new feature request must be turned into a bounded specification

## Read Order

- `.codex/prompts/speckit.specify.md` first
- `.codex/prompts/speckit.constitution.md` if present
- `.codex/prompts/speckit.clarify.md` only when clarification is part of the assigned scope
- `specs/<feature>/spec.md` if present
- adjacent workflow artifacts only when needed to preserve alignment

## Owned Outputs

- `spec.md`
- clarified scope boundaries
- explicit acceptance criteria and constraints for the assigned feature

## Phase-Specific Rejected Criteria

Return `rejected` if specification work is requested but the actual need is planning, tasking, implementation, or verification.

## Phase-Specific Blocked Criteria

Return `blocked` if essential product intent is missing and clarification cannot be resolved from artifacts or the assigned scope.
