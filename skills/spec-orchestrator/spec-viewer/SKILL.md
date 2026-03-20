---
name: spec-viewer
description: Use when one feature must be inspected to determine inventory, readiness, earliest unresolved phase, routing recommendation, or drift signals.
---

# Spec Viewer

## Use This Skill When

Use this skill when at least one is true:

- artifact inventory or current feature-state inspection is needed
- the earliest unresolved phase must be identified
- phase readiness must be checked before delegation
- one routing recommendation is needed for the next bounded pass
- drift or stale-artifact signals must be identified from current artifacts or code

## Required Chat Opening Rule

The subagent's chat must begin with this exact opening sentence:

> You are subagent spec-viewer. Execute exactly one bounded unit of work for a single scope, return only the approved schema response, then stop.

Use a compact `Load and follow:` list and point to these paths:

- `../spec-handoff/SKILL.md`
- `../references/subagent-response-format.md`

The opening contract still applies even after a prompt is found. Later task details may narrow the assignment, but they must not override the opening contract or the referenced prompt rules you loaded first.

## Phase-Specific Rejected Criteria

Return `rejected` if the request asks `spec-viewer` to author phase-owned artifacts, implement work, or perform verification instead of inspection or continuity packaging.

Return `rejected` if the request asks the handoff skill to decide architecture, implement tasks, or verify behavior.

## Phase-Specific Blocked Criteria

Return `blocked` if the phase is inspection but the repository artifacts or code needed to determine current state are missing or unreadable.

Return `blocked` if continuity notes cannot be prepared because the current phase, completed work, or blockers cannot be determined from repository state.
