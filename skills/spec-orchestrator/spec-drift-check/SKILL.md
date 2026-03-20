---
name: spec-drift-check
description: Detect and record drift between spec artifacts and implementation when requests, code changes, plan changes, or task updates appear to exceed the current spec. Use for scope checks, artifact/code alignment reviews, drift.md updates, and deciding whether work must route back to specification or planning.
---

# Spec Drift Check

Use this skill when scope alignment is the main question.
Use `spec-verifier` instead when the main question is evidence, testing, or verification findings.

## Invocation Opening

Start the subagent instruction with this exact sentence:

> You are subagent spec-drift-check. Execute exactly one bounded unit of work for a single scope, return only the approved schema response, then stop.

## Reinjection Requirements

For every run, the orchestrator should use a compact `Load and follow:` list and point to the relevant contract paths instead of restating the full short-form contract inline.

The subagent must treat those referenced instructions as mandatory for the current run, even if later task details appear more specific.

## Read First

Read in this order:

- `.codex/prompts/speckit.analyze.md` first
- `.codex/prompts/speckit.constitution.md` if present
- equivalent repository prompt locations only if the primary prompt is missing

- `specs/<feature>/spec.md`
- `specs/<feature>/plan.md` if present
- `specs/<feature>/tasks.md` if present
- `specs/<feature>/review.md` if present
- `specs/<feature>/drift.md` if present
- changed code or requested changes that may exceed scope

If the orchestrator bundle uses the standard layout, the shared template is at `../spec-orchestrator/references/drift-report-template.md`.

This skill also follows the shared reinjection contract at `../references/subagent-reinjection-contract.md` and the shared subagent lifecycle contract at `../references/subagent-lifecycle.md` and the shared response schema at `../references/subagent-response-format.md`.

Use `.codex/prompts/speckit.analyze.md` as the primary repository prompt when that file exists. Also apply `.codex/prompts/speckit.constitution.md` when present. If the primary prompt is not found, search other prompt locations in the repository before falling back to this bundle. Apply the fallback chain and `blocked`/`rejected` criteria in `../references/subagent-prompt-fallbacks.md`.

## Goal

Decide whether a request, artifact, or implementation change stays within the current spec contract.

## Use This Skill For

- checking whether implementation has moved ahead of artifacts
- checking whether a new request exceeds `spec.md`
- deciding whether a discrepancy is clarification or true drift
- updating `drift.md` with a concise structured note

## Do Not Use This Skill For

- writing a new specification from scratch
- creating the implementation plan
- decomposing tasks
- doing a full code implementation pass

## Phase-Specific Rejected Criteria

Return `rejected` if the request is actually asking for new specification authoring rather than drift assessment.

## Phase-Specific Blocked Criteria

Return `blocked` if scope alignment cannot be determined from available artifacts and code evidence.

## Procedure

1. Identify the current scope boundary from `spec.md`.
2. Compare the proposed or implemented behavior against that boundary.
3. Treat clarifications that do not expand behavior as in-scope.
4. Treat new behavior, new integrations, new surfaces, or materially broader scope as drift.
5. Update `drift.md` using the shared template when drift is confirmed.
6. Recommend the earliest phase that must be revisited.

## Output Rules

- Prefer short structured notes over long prose.
- State whether the result is `in scope`, `clarification`, or `drift`.
- If drift exists, say whether it routes back to specification or planning.
- Name the affected artifacts and code paths explicitly.

## Return Contract

Return results using the shared schema at `../references/subagent-response-format.md`.

Additional rule for this skill:

- `Scope` must name exactly one drift assessment.
- `Recommended Next Phase` must contain exactly one orchestrator-facing next step.
