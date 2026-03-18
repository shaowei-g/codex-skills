---
name: spec-drift-check
description: Detect and record drift between Spec Kit artifacts and implementation when requests, code changes, plan changes, or task updates appear to exceed the current spec. Use for scope checks, artifact/code alignment reviews, drift.md updates, and deciding whether work must route back to specification or planning.
---

# Spec Drift Check

Use this skill when scope alignment is the main question.

## Read First

Read in this order:

- `spec.md`
- `plan.md` if present
- `tasks.md` if present
- `review.md` if present
- `drift.md` if present
- changed code or requested changes that may exceed scope

If the orchestrator bundle uses the standard layout, the shared template is at `../spec-orchestrator/references/drift-report-template.md`.

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

## Return Shape

```markdown
Result:

- in scope | clarification | drift

Affected Files:

- ...

Reason:

- ...

Recommended Phase:

- specification | planning | implementation
```
