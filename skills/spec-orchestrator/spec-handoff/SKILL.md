---
name: spec-handoff
description: Prepare structured spec handoff state for paused, blocked, resumed, or transferred feature work. Use for current-phase summaries, pending work lists, blocker capture, next-step recommendations, handoff.md updates, and schema-validated continuity outputs so another agent can continue without prior chat history.
---

# Spec Handoff

Use this skill when handoff or continuity packaging is the current phase for one feature.

## Shared Contracts

Load and follow these shared references first:

- `../references/specialist-execution-contract.md`
- `../references/subagent-response-format.md`

## Helper Scripts

- workflow executor: `./scripts/prepare_handoff.sh`
- handoff markdown renderer: `./scripts/render_handoff_template.sh`
- fixed response formatter: `./scripts/print_handoff_response_schema.sh`
- helper validator: `./scripts/validate_handoff_response.sh`

These scripts can assist with deriving handoff state and rendering `handoff.md`, but the orchestrator still treats the shared response schema and shared validator as the final transport contract.

## Purpose

Use this skill for:

- ending a bounded orchestration pass
- pausing partially completed work
- summarizing blockers before stopping
- preparing resumption context for another agent
- packaging continuity state so the next agent can continue without chat history

## Read Order

- `specs/<feature>/handoff.md` if present
- `specs/<feature>/spec.md` if present
- `specs/<feature>/plan.md` if present
- `specs/<feature>/tasks.md` if present
- `specs/<feature>/review.md` if present
- `specs/<feature>/drift.md` if present
- current code or task state only when resuming work

Shared template:

- `../references/handoff-template.md`

## Owned Outputs

- `handoff.md`
- concise current-phase summary
- pending work, blockers, and exact recommended next reading path

## Phase-Specific Rejected Criteria

Return `rejected` if the request actually asks for architecture design, implementation, or verification instead of continuity packaging.

## Phase-Specific Blocked Criteria

Return `blocked` if the current phase, completed work, or blockers cannot be determined from repository state.
