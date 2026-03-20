---
name: spec-drift-check
description: Detect and record drift between spec artifacts and implementation when requests, code changes, plan changes, or task updates appear to exceed the current spec. Use for scope checks, artifact/code alignment reviews, drift.md updates, and deciding whether work must route back to specification or planning.
---

# Spec Drift Check

Use this skill when drift assessment is the current phase for one feature.

## Shared Contracts

Load and follow these shared references first:

- `../references/specialist-execution-contract.md`
- `../references/artifact-acceptance-markers.md`
- `../references/subagent-response-format.md`
- `../references/specialist-status-semantics.md`

## Purpose

Decide whether a request, artifact, or implementation change stays within the current spec contract.

Use this skill for:

- checking whether implementation has moved ahead of artifacts
- checking whether a new request exceeds `spec.md`
- deciding whether a discrepancy is clarification or true drift
- updating `drift.md` with a concise structured note

## Read Order

- `.codex/prompts/speckit.analyze.md` first
- `.codex/prompts/speckit.constitution.md` if present
- `specs/<feature>/spec.md` and its marker state
- `specs/<feature>/plan.md` if present and its marker state
- `specs/<feature>/tasks.md` if present and its marker state
- `specs/<feature>/implementation-status.md` if present
- `specs/<feature>/review.md` if present
- `specs/<feature>/drift.md` if present
- changed code or requested changes that may exceed scope

Shared template:

- `../references/drift-report-template.md`

## Owned Outputs

- one drift assessment
- `drift.md` updates when drift is confirmed
- advisory route-back recommendation when scope has been exceeded

## Phase-Specific Rejected Criteria

Return `rejected` if the request is actually asking for new specification authoring rather than drift assessment.

## Phase-Specific Blocked Criteria

Return `blocked` if scope alignment cannot be determined from available artifacts and code evidence.

## Procedure

1. identify the current scope boundary from `spec.md`
2. compare proposed or implemented behavior against that boundary
3. treat clarifications that do not expand behavior as in scope
4. treat new behavior, new integrations, new surfaces, or materially broader scope as drift
5. update `drift.md` using the shared template when drift is confirmed
6. recommend the earliest phase that must be revisited
