---
name: spec-viewer
description: Use when one feature must be inspected to determine inventory, readiness, earliest unresolved phase, routing recommendation, or drift signals.
---

# Spec Viewer

Use this skill when inspection is the current phase for one feature.

## Shared Contracts

Load this shared shortcut first:

- `../references/shared-specialist-contract.md`

Open the deeper canonical shared references only when the shortcut is insufficient for the current situation.

## Purpose

Use this skill when at least one is true:

- artifact inventory or current feature-state inspection is needed
- the earliest unresolved phase must be identified
- phase readiness must be checked before delegation
- one routing recommendation is needed for the next bounded pass
- drift or stale-artifact signals must be identified from current artifacts or code

## Read Order

- repository-local workflow inspection prompt when available
- `specs/<feature>/handoff.md` if present
- `specs/<feature>/spec.md` if present
- `specs/<feature>/plan.md` if present
- `specs/<feature>/tasks.md` if present
- `specs/<feature>/implementation-status.md` if present
- `specs/<feature>/review.md` if present
- `specs/<feature>/drift.md` if present
- changed code only when artifact state alone is insufficient

## Owned Outputs

- inspection summary in the shared schema
- authoritative inspection verdict for current workflow state based on repository evidence
- advisory next-phase recommendation based on repository evidence
- minimal continuity notes only when the assigned scope explicitly asks for them

## Phase-Specific Rejected Criteria

Return `rejected` if the request asks this skill to author phase-owned artifacts, implement work, or perform verification instead of inspection.
Return `rejected` if the request tries to force a pre-decided route and treats inspection as confirmation-only instead of allowing a truthful current-state report.

## Phase-Specific Blocked Criteria

Return `blocked` if the repository artifacts or code needed to determine current state are missing or unreadable.
