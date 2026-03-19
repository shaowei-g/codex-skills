# Codex Prompt Mapping

Use these repository prompt paths when they exist.

All paths are relative to the repository root.

## Primary Prompt Mapping by Phase

- Specification: `.codex/prompts/speckit.specify.md`
- Technical planning: `.codex/prompts/speckit.plan.md`
- Task decomposition: `.codex/prompts/speckit.tasks.md`
- Implementation: `.codex/prompts/speckit.implement.md`
- Verification and review: `.codex/prompts/speckit.checklist.md`
- Drift assessment: `.codex/prompts/speckit.analyze.md`
- Clarification before or during specification: `.codex/prompts/speckit.clarify.md`
- Constitution or governing constraints: `.codex/prompts/speckit.constitution.md`
- Task export to issue format when explicitly requested: `.codex/prompts/speckit.taskstoissues.md`
- Feature state inspection and routing recommendation: repository-local workflow inspection prompt when available, otherwise local `spec-viewer` rules

## Lookup Rule

For every subagent run:

1. Check the primary prompt for the assigned phase.
2. Also check `.codex/prompts/speckit.constitution.md` when present and apply it as a governing constraint.
3. Use `.codex/prompts/speckit.clarify.md` only when clarification work is explicitly part of the assigned scope or the primary phase prompt instructs it.
4. If the primary prompt is not present, search other repository prompt locations for an equivalent phase prompt.
5. If no repository prompt exists, fall back to the local agent and reference rules in this bundle.

## Scope Guard

The existence of additional prompt files does not authorize extra phases.
A subagent must still execute exactly one assigned scope in one run.


## Failure Classification Reference

Use `./subagent-prompt-fallbacks.md` to decide when prompt discovery failure is still recoverable as local fallback, when it is `blocked`, and when the request must be `rejected`.
