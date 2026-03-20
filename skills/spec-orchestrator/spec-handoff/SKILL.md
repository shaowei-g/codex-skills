---
name: spec-handoff
description: Prepare structured spec handoff state for paused, blocked, resumed, or transferred feature work. Use for current-phase summaries, pending work lists, blocker capture, next-step recommendations, handoff.md updates, and schema-validated continuity outputs so another agent can continue without prior chat history.
---

# Spec Handoff

Use this skill for continuity, inspection, and handoff packaging.

## Script Assets

- Workflow executor: `./scripts/prepare_handoff.sh`
- Handoff markdown renderer: `./scripts/render_handoff_template.sh`
- Fixed response formatter: `./scripts/print_handoff_response_schema.sh`
- Response validator: `./scripts/validate_handoff_response.sh`

These scripts do the real work: read feature artifacts, derive handoff state, classify review and drift findings, optionally write `handoff.md`, emit the fixed schema, and validate the result.

## Invocation Opening

Start the subagent instruction with this exact sentence:

> You are subagent spec-handoff. Your task is to execute exactly one bounded unit of work for a single scope, produce a response in the predefined output format, and terminate immediately after returning the result.

## Read First

- equivalent repository prompt locations only if the primary prompt is missing
- `specs/<feature>/handoff.md` if present
- `specs/<feature>/spec.md` if present
- `specs/<feature>/plan.md` if present
- `specs/<feature>/tasks.md` if present
- `specs/<feature>/review.md` if present
- `specs/<feature>/drift.md` if present

Read current code or task state only when resuming work.

Shared references:

- template: `../references/handoff-template.md`
- reinjection contract: `../references/subagent-reinjection-contract.md`
- lifecycle contract: `../references/subagent-lifecycle.md`
- response schema: `../references/subagent-response-format.md`
- fallback rules: `../references/subagent-prompt-fallbacks.md`

## Goal

Leave the feature in a state where the next agent can continue safely without relying on chat history.

## Use This Skill For

- feature-state inspection when legacy inspection flows still point at `spec-viewer`
- routing recommendations derived from durable artifacts
- ending a bounded orchestration pass
- pausing partially completed work
- summarizing blockers before stopping
- preparing resumption context for another agent

## Do Not Use This Skill For

- deciding the full technical approach
- replacing verification or drift analysis
- implementing new feature work

## Procedure

1. Run `./scripts/prepare_handoff.sh` with one feature slug and one bounded handoff scope.
2. Let it derive current phase, completed work, pending work, blockers, unresolved questions, review evidence, finding classes, drift findings, and the advisory next step.
3. When a durable continuity note is required, let `./scripts/prepare_handoff.sh --write` call `./scripts/render_handoff_template.sh` to update `handoff.md`.
4. Validate the final response with `./scripts/validate_handoff_response.sh`.
5. Return the exact field order emitted by `./scripts/print_handoff_response_schema.sh`.

## Output Rules

- Keep it concise and scannable.
- Prefer bullets and short phrases.
  [text](../references)- Do not restate the entire feature history.
- If the workflow should route backward, say so clearly.
- Do not improvise section names or field order in the final response.

## Return Contract

Return results using `../references/subagent-response-format.md` and the exact field order from `./scripts/print_handoff_response_schema.sh`.
