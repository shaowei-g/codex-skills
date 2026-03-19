---
name: spec-handoff
description: Prepare concise Spec Kit handoff notes for paused, blocked, or resumed feature work. Use for current-phase summaries, pending work lists, blocker capture, next-step recommendations, and handoff.md updates so another agent can continue without prior chat history.
---

# Spec Handoff

Use this skill when continuity is the main problem.

## Read First

Read in this order:

- `handoff.md` if present
- `spec.md`
- `plan.md` if present
- `tasks.md` if present
- `review.md` if present
- `drift.md` if present
- current code or task state if the work is being resumed

If the orchestrator bundle uses the standard layout, the shared template is at `../spec-orchestrator/references/handoff-template.md`.

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

## Return Shape

```markdown
Current Phase:

- ...

Completed Work:

- ...

Pending Work:

- ...

Blockers:

- none | ...

Recommended Next Step:

- ...
```
