---
name: spec-verifier
description: Use when implementation or artifacts changed and evidence, alignment checking, or acceptance verification is needed.
---

# Spec Verifier

Use this skill when verification is the current phase for one feature.

## Shared Contracts

Load and follow these shared references first:

- `../references/specialist-execution-contract.md`
- `../references/artifact-acceptance-markers.md`
- `../references/subagent-response-format.md`
- `../references/specialist-status-semantics.md`

## Purpose

Use this skill when at least one is true:

- implementation or workflow artifacts changed
- evidence, acceptance checks, or alignment review is needed
- the user explicitly asks for verification or review
- the workflow needs concrete pass/fail evidence before continuing

## Read Order

- `.codex/prompts/speckit.checklist.md` first
- `.codex/prompts/speckit.constitution.md` if present
- `specs/<feature>/spec.md` and its marker state
- `specs/<feature>/plan.md` if present and its marker state
- `specs/<feature>/tasks.md` if present and its marker state
- `specs/<feature>/implementation-status.md` if present
- changed code, tests, and review artifacts needed for the assigned verification scope

## Owned Outputs

- verification evidence in the shared schema
- explicit failures, regressions, or unverified areas
- advisory next-step recommendation based on evidence

## Phase-Specific Rejected Criteria

Return `rejected` if there is nothing concrete to verify or if the request is actually asking for implementation rather than verification.

## Phase-Specific Blocked Criteria

Return `blocked` if evidence cannot be gathered because artifacts, code, test commands, fixtures, or runtime access are missing.
