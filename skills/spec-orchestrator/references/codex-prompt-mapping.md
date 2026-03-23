# Codex Prompt Mapping

Use these repository prompt paths when they exist.

All repository prompt paths are relative to the repository root.

Bundle asset paths are fixed under the user skill root when that runtime layout exists:

- `~/.codex/skills/spec-orchestrator/...`
- `~/.codex/skills/codex-cli-subagent-transport/...`

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
- Feature state inspection and routing recommendation: repository-local workflow inspection prompt when available, otherwise local inspection rules

## Fixed-Path Lookup Priority

Before any recursive search, resolve known paths directly in this order:

0. optionally materialize exact installed bundle paths with:
   - `bash ~/.codex/skills/spec-orchestrator/scripts/resolve_bundle_paths.sh --specialist <assigned-subagent>`
1. the assigned phase primary prompt under `.codex/prompts/`
2. `.codex/prompts/speckit.constitution.md` when present
3. `.codex/prompts/speckit.clarify.md` only when clarification is part of scope
4. the assigned specialist skill under `~/.codex/skills/spec-orchestrator/<specialist>/SKILL.md`
5. shared orchestrator references under `~/.codex/skills/spec-orchestrator/references/`
6. transport assets under `~/.codex/skills/codex-cli-subagent-transport/`

Only fall back to repository-wide or workspace-wide search when a required direct path is missing or unreadable.

## Lookup Rule

For every delegated run:

1. Check the primary prompt for the assigned phase.
2. Also check `.codex/prompts/speckit.constitution.md` when present and apply it as a governing constraint.
3. Use `.codex/prompts/speckit.clarify.md` only when clarification work is explicitly part of the assigned scope or the primary phase prompt instructs it.
4. Resolve specialist and transport bundle assets from their fixed `~/.codex/skills/...` paths before any recursive search, preferably from `resolve_bundle_paths.sh` output.
5. If the primary prompt is not present, search other repository prompt locations for an equivalent prompt for the same phase.
6. If no repository prompt exists, fall back to the assigned specialist skill and shared local references in this bundle.

## Scope Guard

- Additional prompt files do not authorize extra phases.
- A delegated run still owns exactly one assigned scope in one assigned phase.
- Fixed-path resolution is a speed and reliability preference only; it does not change routing authority.

## Related References

- lifecycle: `./subagent-lifecycle.md`
- orchestrator fallback and repair: `./orchestrator-fallback.md`
- response schema: `./subagent-response-format.md`
