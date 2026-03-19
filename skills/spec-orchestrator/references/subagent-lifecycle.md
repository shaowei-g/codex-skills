# Subagent Lifecycle Contract

This reference defines the required operating lifecycle for every specialist subagent used by `spec-orchestrator`.

## Lifecycle

Every subagent run must follow this exact sequence:

1. **Create**
   - Instantiate the subagent for one named feature and one named scope.
   - Bind the run to exactly one phase-owned assignment.
   - Start the run instruction with a direct identity-and-contract opening.
   - Use this exact sentence pattern, substituting the actual subagent name:
     - `You are subagent <subagent-name>. Your task is to execute exactly one bounded unit of work for a single scope, produce a response in the predefined output format, and terminate immediately after returning the result.`
   - Reject or return blocked if the request contains multiple unrelated scopes.

2. **Inject Run Contract**
   - Immediately after the opening sentence, inject the short-form contract from `./subagent-reinjection-contract.md`.
   - Restate one-scope-only, one-phase-only, fixed-format-only, and terminate-immediately rules for this run.

3. **Load Prompt Context**
   - Use the phase-to-prompt mapping in `./references/codex-prompt-mapping.md`.
   - Search `.codex/prompts/` first for the exact phase prompt.
   - Also load `.codex/prompts/speckit.constitution.md` when present as a governing constraint.
   - If the mapped phase prompt is not found, search other prompt locations in the repository for an equivalent phase prompt.
   - If no repository prompt exists, continue with the artifact contract and phase rules in this bundle.
   - Prefer repository-local prompts over bundle-local prose whenever both exist.

3. **Load Feature Context**
   - Read only the artifacts and code needed for the assigned scope.
   - Prefer the feature's durable workflow notes over chat history.
   - Use `specs/<feature>/` as the feature artifact directory.
   - Do not assume ownership of later phases.

5. **Validate Entry Gate**
   - Check the subagent's documented entry gate.
   - If the gate fails, stop without doing adjacent-phase work.
   - Return a blocked result in the shared response format.

5. **Execute Single Scope**
   - Perform only the assigned bounded unit of work.
   - Follow the applicable repository prompt or template if one was found.
   - Do not expand into a second batch, second phase, or parallel scope.
   - Record blockers or drift instead of absorbing additional work.

6. **Persist Durable Outputs**
   - Update only the files required by the assigned scope.
   - Write concrete artifact updates before returning whenever possible.
   - If no file change is safe, explain why in the return payload.

7. **Return Fixed Response**
   - Return output using the shared response schema in `./references/subagent-response-format.md`.
   - Include scope, status, files touched, blockers, drift, evidence, and recommended next phase.
   - Do not return free-form summaries in place of the schema.

11. **Shutdown**
   - Stop immediately after returning the result.
   - Do not self-continue, monitor, or auto-invoke another phase.
   - Hand control back to the orchestrator.

## Single-Scope Rule

A subagent run may own **exactly one scope**.

A scope must be small enough to validate in one pass, for example:

- create or revise one `spec.md`
- create or revise one `plan.md`
- create or revise one `tasks.md`
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
- repository prompt mapping and lookup order
- expected artifact or batch
- stop-after-completion instruction
- required response schema reference

The orchestrator validates the returned payload and decides whether another subagent run is needed.

## Prompt Failure and Classification

Use `./subagent-prompt-fallbacks.md` for the required fallback chain and for deciding whether a prompt problem or missing prerequisite must return `blocked` or `rejected`.
