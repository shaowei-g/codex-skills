# Subagent Lifecycle Contract

This reference defines the required operating lifecycle for every specialist subagent used by `spec-orchestrator`.

## Lifecycle

Every subagent run must follow this exact sequence:

1. **Create**
   - Instantiate the subagent for one named feature and one named scope.
   - Bind the run to exactly one phase-owned assignment.
   - Start the run instruction with a direct identity-and-contract opening.
   - Use this exact sentence pattern, substituting the actual subagent name:
     - `You are subagent <subagent-name>. Execute exactly one bounded unit of work for a single scope, return only the approved schema response, then stop.`
   - Reject or return blocked if the request contains multiple unrelated scopes.

2. **Inject Run Contract**
   - Immediately after the opening sentence, provide a compact `Load and follow:` list.
   - Point to the specialist skill, the repository phase prompt, and the shared response schema by path.
   - Restate only the run-specific fields that are not already covered by those referenced files.
   - Do not paste the full reinjection checklist inline when the subagent can load the referenced files directly.

3. **Load Prompt Context**
   - Use the phase-to-prompt mapping in `./references/codex-prompt-mapping.md`.
   - Search `.codex/prompts/` first for the exact phase prompt.
   - Also load `.codex/prompts/speckit.constitution.md` when present as a governing constraint.
   - If the mapped phase prompt is not found, search other prompt locations in the repository for an equivalent phase prompt.
   - If no repository prompt exists, continue with the artifact contract and phase rules in this bundle.
   - Prefer repository-local prompts over bundle-local prose whenever both exist.

4. **Load Feature Context**
   - Read only the artifacts and code needed for the assigned scope.
   - Prefer the feature's durable workflow notes over chat history.
   - Use `specs/<feature>/` as the feature artifact directory.
   - Do not assume ownership of later phases.

5. **Validate Entry Gate**
   - Check the subagent's documented entry gate.
   - If the gate fails, stop without doing adjacent-phase work.
   - Return a blocked result in the shared response format.

6. **Execute Single Scope**
   - Perform only the assigned bounded unit of work.
   - Follow the applicable repository prompt or template if one was found.
   - Do not expand into a second batch, second phase, or parallel scope.
   - Record blockers or drift instead of absorbing additional work.

7. **Persist Durable Outputs**
   - Update only the files required by the assigned scope.
   - Write concrete artifact updates before returning whenever possible.
   - If no file change is safe, explain why in the return payload.

8. **Return Fixed Response**
   - Return output using the shared response schema in `./references/subagent-response-format.md`.
   - Use `./scripts/print_subagent_response_schema.sh` when a fixed template is needed to keep the response in the approved shape.
   - Include scope, status, files touched, blockers, drift, evidence, and recommended next phase.
   - Do not return free-form summaries in place of the schema.

9. **Shutdown**
   - Stop immediately after returning the result.
   - Do not self-continue, monitor, or auto-invoke another phase.
   - Hand control back to the orchestrator.

## Single-Scope Rule

A subagent run may own **exactly one scope**.

A scope must be small enough to validate in one pass, for example:

- create or revise one `spec.md`
- create or revise one `plan.md`
- create or revise one `tasks.md`
- inspect one feature state and recommend one next valid phase
- implement one bounded batch from `tasks.md`
- verify one latest completed batch
- assess one drift question
- prepare one handoff update

The following are invalid for one subagent run:

- multiple batches
- multiple features
- multiple phases
- open-ended continuation
- phase chaining after completion

## Orchestrator Integration Rule

The orchestrator must delegate with all of the following made explicit:

- target feature
- artifact directory path
- assigned scope
- delegated assigned-phase value
- delegated assigned-subagent value
- specialist skill reference
- repository prompt reference
- required response schema reference
- response validator reference
- allowed write set
- forbidden write set
- stop-after-completion instruction

The default delegation form is the compact required-fields plus path-references prompt.
The orchestrator should reference shared contracts by path instead of expanding them inline unless the runtime cannot read those paths.

The orchestrator validates the returned payload and decides whether another subagent run is needed.

When the orchestrator runs the shared validator, it must invoke it as `bash ./scripts/validate_subagent_response.sh`.
Do not assume the validator script has an executable bit.

If native subagent support is unavailable, the orchestrator must load and apply `~/.codex/skills/codex-cli-subagent-transport/SKILL.md` as the transport contract.

Transport invariants remain:

- read only `response_file` as the authoritative delegated result
- treat `exec_log` as diagnostics only
- validate `response_file` with `bash ./scripts/validate_subagent_response.sh`
- do not infer subagent output from terminal chatter or execution logs

## Validation and repair boundary

The first returned payload must already satisfy the shared validator.

If the orchestrator reports a repairable format-only defect, the subagent may perform exactly one repair pass with these limits:

- preserve the original feature, assigned phase, assigned subagent, and scope
- preserve the original meaning of files changed, blockers, drift, and evidence
- do not perform new analysis or additional file work
- do not upgrade a blocked or rejected result into completed because of the repair

If the response would require semantic reinterpretation instead of structural correction, the orchestrator must reject it.

## Prompt Failure and Classification

Use `./subagent-prompt-fallbacks.md` for the required fallback chain and for deciding whether a prompt problem or missing prerequisite must return `blocked` or `rejected`.
