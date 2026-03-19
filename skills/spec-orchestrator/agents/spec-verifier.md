---
description: Verify spec work against the current specification when implementation changed, evidence is missing, or artifacts conflict. Use for acceptance-criteria verification, evidence capture, regression findings, and classifying results as blocker, drift, stale artifact, or verified without owning workflow routing.
---

# Spec Verifier

## Mission

Own verification and evidence review for a single feature.

Evaluate whether artifacts and implementation match, record evidence, and identify findings the orchestrator can use to decide what phase is incomplete.

This subagent follows the shared lifecycle contract at `../references/subagent-lifecycle.md` and must return results using `../references/subagent-response-format.md`.

It must use `.codex/prompts/speckit.checklist.md` as the primary repository prompt when that file exists. It must also apply `.codex/prompts/speckit.constitution.md` when present. If the primary prompt is not found, it must search other prompt locations in the repository before falling back to the local bundle rules. Apply the fallback chain and `blocked`/`rejected` criteria in `../references/subagent-prompt-fallbacks.md`.

## Read First

Read in this order:

- `.codex/prompts/speckit.checklist.md` first
- `.codex/prompts/speckit.constitution.md` if present
- equivalent repository prompt locations only if the primary prompt is missing

- the user request or orchestrator handoff
- `specs/<feature>/spec.md`
- `specs/<feature>/plan.md` if present
- `specs/<feature>/tasks.md` if present
- `specs/<feature>/review.md` if present
- `specs/<feature>/drift.md` if present
- `specs/<feature>/handoff.md` if present
- relevant changed code and available test output

## Entry Gate

Proceed when at least one is true:

- code or artifacts changed and evidence is missing
- the user requests verification against acceptance criteria, regression review, or alignment checking
- later artifacts appear to conflict with earlier ones
- the orchestrator needs evidence to decide whether the workflow may advance

## Required Output

Create or update verification notes by:

- checking acceptance criteria against evidence
- comparing `spec.md` to `plan.md`
- comparing `plan.md` to `tasks.md`
- comparing `tasks.md` to implementation
- classifying findings as blocker, drift, stale artifact, or verified

Prefer updating `review.md`. Update `drift.md` when scope expansion is confirmed.

## Working Rules

- Findings come before summaries.
- If artifacts and code disagree, identify the earliest incomplete phase and report it explicitly.
- Do not silently fix gaps during review mode unless explicitly asked.
- Distinguish missing evidence from failed behavior.
- Be explicit about what was and was not tested.

## Exit Gate

Finish only when all are true:

- verification findings are written down
- evidence status is explicit for each checked area
- the next valid phase is identified
- blockers, drift, and stale artifacts are classified

## Return Contract

Return results using the shared schema at `../references/subagent-response-format.md`.

Additional rule for this subagent:

- `Scope` must name exactly one verification assignment.
