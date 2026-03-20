# Delegated Run Lifecycle

This reference defines only the operating sequence that `spec-orchestrator` should follow for one delegated specialist run.

Scope ownership, required delegated fields, authority limits, and violation labels are defined in `./subagent-reinjection-contract.md`.

## Lifecycle

Every delegated run should follow this sequence:

1. **Prepare Assignment**
   - determine the earliest unresolved phase
   - select the mapped specialist
   - define one bounded unit of work for the chosen run

2. **Inject**
   - open with the delegated identity-and-stop instruction
   - provide the run-specific assignment values
   - prefer path references over pasted contracts when the runtime can load files reliably

3. **Load Prompt and Local Context**
   - resolve repository prompts using `./codex-prompt-mapping.md`
   - load only the feature artifacts and repository context needed for the assigned scope
   - prefer durable workflow artifacts over chat history
- when markerized artifacts exist, inspect formal acceptance using `./artifact-acceptance-markers.md` before routing forward

4. **Check Entry Gate**
   - consult the assigned specialist skill for phase-local entry expectations
   - if the gate fails, stop without doing adjacent-phase work
   - return only an allowed schema status

5. **Execute Assigned Work**
   - perform the delegated bounded unit of work only
   - keep file updates within the assigned ownership set
   - record blockers or drift instead of absorbing adjacent work

6. **Persist Durable Outputs**
   - write only the artifacts owned by the assigned specialist and scope
   - if no safe write is possible, explain that in the delegated response

7. **Collect Response**
   - require the fixed schema in `./subagent-response-format.md`
   - validate the returned payload before accepting it

8. **Stop**
   - end the delegated run after the response is returned
   - do not self-continue or route into another delegated pass from inside the same run

## Related References

- prompt lookup: `./codex-prompt-mapping.md`
- artifact acceptance: `./artifact-acceptance-markers.md`
- delegated prompt contract and authority checks: `./subagent-reinjection-contract.md`
- fallback and repair: `./orchestrator-fallback.md`
- response schema: `./subagent-response-format.md`

## Acceptance Checkpoint

If the delegated run updates or relies on markerized phase artifacts for formal acceptance or continuation, validate them before treating the phase as accepted:

- `bash ./scripts/validate_artifact_markers.sh specs/<feature>`
- use `--require-markers` when the updated artifacts are expected to carry front matter markers
