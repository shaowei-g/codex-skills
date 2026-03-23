---
name: spec-viewer
description: Use when one feature must be inspected to determine inventory, readiness, earliest unresolved phase, routing recommendation, or drift signals.
---

# Spec Viewer

Use this skill when inspection is the current phase for one feature.

## Shared Contracts

Load and follow these shared references first:

- `../references/specialist-execution-contract.md`
- `../references/artifact-acceptance-markers.md`
- `../references/subagent-response-format.md`
- `../references/specialist-status-semantics.md`

## Purpose

Use this skill when at least one is true:

- artifact inventory, acceptance-marker inspection, or current feature-state inspection is needed
- the earliest unresolved phase must be identified
- phase readiness must be checked before delegation
- one routing recommendation is needed for the next bounded pass
- drift or stale-artifact signals must be identified from current artifacts or code

## Read Order

- repository-local workflow inspection prompt when available
- `specs/<feature>/handoff.md` if present
- `specs/<feature>/spec.md` if present and inspect front matter markers when present
- `specs/<feature>/plan.md` if present and inspect front matter markers when present
- `specs/<feature>/tasks.md` if present and inspect front matter markers when present
- `specs/<feature>/implementation-status.md` if present
- `specs/<feature>/review.md` if present
- `specs/<feature>/drift.md` if present
- changed code only when artifact state alone is insufficient

## Owned Outputs

- inspection summary in the shared schema
- authoritative inspection verdict for current workflow state based on accepted markers when available
- advisory next-phase recommendation based on accepted markers when available
- minimal continuity notes only when the assigned scope explicitly asks for them

## Phase-Specific Rejected Criteria

Return `rejected` if the request asks this skill to author phase-owned artifacts, implement work, or perform verification instead of inspection.
Return `rejected` if the request tries to force a pre-decided route and treats inspection as confirmation-only instead of allowing a truthful current-state report.

## Phase-Specific Blocked Criteria

Return `blocked` if the repository artifacts or code needed to determine current state are missing or unreadable.
