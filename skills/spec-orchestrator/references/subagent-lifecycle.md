# Delegated Run Lifecycle

This reference defines only the operating sequence that `spec-orchestrator` should follow for one delegated specialist run.

Scope ownership, required delegated fields, authority limits, and violation labels are defined in `./subagent-reinjection-contract.md`.

## Lifecycle

Every delegated run should follow this sequence:

1. **Prepare Assignment**
   - determine the earliest unresolved phase candidate
   - before delegating fresh inspection, check whether a reusable routing snapshot exists for the feature
   - a reusable snapshot may shortcut repeated inspection only when its fingerprint matches current feature artifacts and its validation metadata is still authoritative
   - on snapshot miss, stale, or invalid status, continue with normal inspection routing
   - select the mapped specialist
   - define one bounded unit of work for the chosen run
   - do not state an authoritative workflow-phase conclusion yet unless validated artifact markers already establish it

2. **Inject**
   - open with the delegated identity-and-stop instruction
   - provide the run-specific assignment values
   - use the exact mapped specialist identity for native delegation rather than a generic exploration agent
   - for write-owning scopes, confirm the delegated agent can perform workspace file edits before treating native execution as available
   - if the available native agent is read-only or mismatched, treat native execution as unavailable and use the external transport fallback instead of attempting the wrong agent
   - prefer path references over pasted contracts when the runtime can load files reliably
   - when using Codex CLI transport, prepare a repo-local prompt file for `bash ../../codex-cli-subagent-transport/scripts/run_codex_cli_subagent.sh`

3. **Load Prompt and Local Context**
   - resolve repository prompts using `./codex-prompt-mapping.md`
   - prefer fixed known paths before recursive search:
   - optionally resolve exact installed bundle paths first with `bash ~/.codex/skills/spec-orchestrator/scripts/resolve_bundle_paths.sh --specialist <assigned-subagent>`
   - `.codex/prompts/<phase prompt>.md`
   - `.codex/prompts/speckit.constitution.md`
   - `~/.codex/skills/spec-orchestrator/...`
   - `~/.codex/skills/codex-cli-subagent-transport/...`
   - avoid repository-wide `**/...` discovery when the needed bundle assets live at stable `~/.codex` paths
   - load only the feature artifacts and repository context needed for the assigned scope
   - prefer durable workflow artifacts over chat history
   - when markerized artifacts exist, inspect formal acceptance using `./artifact-acceptance-markers.md` before routing forward
   - when current state remains unclear or conflicting, delegate inspection and defer authoritative routing until the schema-valid inspection result returns

4. **Check Entry Gate**
   - consult the assigned specialist skill for phase-local entry expectations
   - if the gate fails, stop without doing adjacent-phase work
   - return only an allowed schema status

5. **Execute Assigned Work**
   - perform the delegated bounded scope only
   - do not widen the assignment, choose the next phase, or continue into follow-on work

6. **Persist Durable Outputs**
   - only when the assigned specialist and scope allow file changes
   - keep ownership within the declared artifact set
   - preserve artifact marker rules when markerized workflow artifacts are touched

7. **Collect Authoritative Result**
   - when using Codex CLI transport, read `manifest.json` or `manifest.env` first to locate run artifacts
   - read the delegated `response_file`
   - treat `response_file` as authoritative
   - treat logs as diagnostics only
   - do not rely on workspace globbing or `/tmp` discovery to find delegated outputs after the run
   - if no authoritative delegated payload exists after the single delegated attempt, stop and classify the run as `blocked`

8. **Validate and Accept**
   - validate the response schema
   - run artifact marker validation when acceptance or continuation depends on markerized artifacts
   - after accepting a schema-valid inspection result or a marker-validated phase-owned update, refresh the repo-local routing snapshot
   - snapshot refresh must be driven from the authoritative delegated response, not from logs
   - verify the refreshed snapshot by rereading it immediately after write and fail the validator on mismatch
   - use one format-only repair pass only when allowed by `./orchestrator-fallback.md`
   - route based on validated markers or the current schema-valid specialist result, not pre-delegation summary text

9. **Stop**
   - stop after the single bounded run is accepted, blocked, or rejected
   - do not start transport debugging or a second delegated attempt inside the same feature run

## Related References

- prompt lookup: `./codex-prompt-mapping.md`
- delegation contract: `./subagent-reinjection-contract.md`
- fallback and repair: `./orchestrator-fallback.md`
- external Codex CLI transport skill: `../../codex-cli-subagent-transport/references/manifest-based-run-contract.md`
- anti-pattern guardrails: `./orchestrator-anti-patterns.md`
