---
name: spec-handoff
description: Prepare concise spec handoff notes for paused, blocked, or resumed feature work. Use for current-phase summaries, pending work lists, blocker capture, next-step recommendations, and handoff.md updates so another agent can continue without prior chat history.
---

# Spec Handoff

Use this skill when continuity is the main problem.

## Read First

Read in this order:

- `.codex/prompts/speckit.checklist.md` first
- `.codex/prompts/speckit.constitution.md` if present
- equivalent repository prompt locations only if the primary prompt is missing

- `specs/<feature>/handoff.md` if present
- `specs/<feature>/spec.md`
- `specs/<feature>/plan.md` if present
- `specs/<feature>/tasks.md` if present
- `specs/<feature>/review.md` if present
- `specs/<feature>/drift.md` if present
- current code or task state if the work is being resumed

If the orchestrator bundle uses the standard layout, the shared template is at `../references/handoff-template.md`.

This skill also follows the shared subagent lifecycle contract at `../references/subagent-lifecycle.md` and the shared response schema at `../references/subagent-response-format.md`.

Use `.codex/prompts/speckit.checklist.md` as the primary repository prompt when that file exists. Also apply `.codex/prompts/speckit.constitution.md` when present. If the primary prompt is not found, search other prompt locations in the repository before falling back to this bundle. Apply the fallback chain and `blocked`/`rejected` criteria in `../references/subagent-prompt-fallbacks.md`.

## Goal

Leave the feature in a state where the next agent can continue safely without relying on chat history.

## Use This Skill For

- ending a bounded orchestration pass
- pausing partially completed work
- summarizing blockers before stopping
- preparing resumption context for another agent

## Do Not Use This Skill For

- deciding the full technical approach
- replacing verification or drift analysis
- implementing new feature work

## Procedure

1. Identify the current workflow phase.
2. Summarize completed work that is durable and real.
3. List pending work that remains inside the approved scope.
4. Record blockers and unresolved questions.
5. State the exact next phase and first file the next agent should read.
6. Update `handoff.md` using the shared template.

## Output Rules

- Keep it concise and scannable.
- Prefer bullets and short phrases.
- Do not restate the entire feature history.
- If the workflow should route backward, say so clearly.

## Return Contract

Return results using the shared schema at `../references/subagent-response-format.md`.

Additional rule for this skill:

- `Scope` must name exactly one handoff update.
- `Recommended Next Phase` must contain exactly one orchestrator-facing next step.
