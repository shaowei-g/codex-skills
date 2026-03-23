# Orchestrator Anti-Patterns and Guardrails

This reference captures common failure modes for `spec-orchestrator` and the guardrails that prevent them.

## 1. Premature State Conclusion

Anti-pattern:

- the orchestrator reads a few artifacts and states that the feature is already inconsistent, incomplete, or at a specific phase before an authoritative inspection result exists

Guardrail:

- for an existing feature with unclear or conflicting state, the orchestrator may collect candidate routing signals only
- authoritative workflow-state conclusions must come from exactly one of:
  - validated artifact acceptance markers from `./artifact-acceptance-markers.md`
  - a schema-valid inspection result from `spec-viewer`
- do not present pre-inspection observations as final routing decisions

## 2. Transport Debugging Inside the Feature Run

Anti-pattern:

- after a delegated execution fails, the orchestrator performs smoke tests, background retries, alternate temp-path experiments, workspace-glob discovery, or unrelated CLI debugging inside the same feature run

Guardrail:

- one delegated step gets at most one execution attempt
- in `standard` mode there is one delegated step; in `booster` mode there may be many sequential steps, but never a retry for the same step
- if that attempt does not produce an authoritative `response_file`, classify the current step as `blocked`
- use a repo-local run manifest to locate delegated outputs rather than rediscovering temp files
- do not turn the current feature run into transport diagnosis work
- transport diagnosis, if needed, should happen outside the bounded feature run or as separate diagnostics only

## 3. Environment Diagnostics Contaminating Feature Reasoning

Anti-pattern:

- permission denials, malformed unrelated skills, shell policy limits, or CLI customization warnings get mixed into the feature-phase narrative

Guardrail:

- environment and transport diagnostics are not feature-state evidence
- keep diagnostics separate from phase reasoning and acceptance reasoning
- use them only to justify `blocked` transport status, never to infer feature completion, drift, or readiness

## 4. Repeated Workaround Loops

Anti-pattern:

- the orchestrator keeps trying new temp paths, cleanup commands, or invocation variants in the same run after the delegated attempt already failed

Guardrail:

- after the delegated attempt for the current step fails, stop that step and the current mode cycle
- do not add a second delegated attempt, background rerun, or workaround loop for the same step
- the only allowed extra step after an authoritative delegated payload exists is validation and one format-only repair pass
- do not bypass the external transport skill with ad hoc raw `codex exec` calls when deterministic run artifacts are required

## 5. Booster Without Explicit Unlock

Anti-pattern:

- the orchestrator sees a user ask to “finish the feature” or “do everything” and silently turns that into a multi-phase execution loop

Guardrail:

- `booster` is allowed only when the current user request explicitly says `mode: booster`
- without that exact unlock, stay in `standard` mode and stop after one validated delegated step
- never treat broad intent language as permission to chain phases automatically

## 6. Summary-As-Acceptance

Anti-pattern:

- prior chat summaries or orchestrator narration are treated as formal phase acceptance

Guardrail:

- formal acceptance comes from artifact markers plus validator checks, not summary text alone
- if markerized artifacts are absent or invalid, routing must rely on the current authoritative inspection result
- never let a previous summary overrule repository evidence or failed marker validation

## 7. Orchestrator Acting Like a Specialist

Anti-pattern:

- the orchestrator performs inspection, implementation, verification, or phase-owned artifact judgment that belongs to the mapped specialist

Guardrail:

- the orchestrator owns routing, delegation, acceptance, and stopping decisions
- specialists own phase-local judgment and outputs
- the orchestrator may gather only the minimum evidence needed to choose the correct specialist or validate markers

## 8. Temp-Path Discovery Instead of Declared Run Artifacts

Anti-pattern:

- the orchestrator writes delegated output to `/tmp/...` and later tries to rediscover it with workspace search or globbing

Guardrail:

- Codex CLI transport should create a repo-local run directory and manifest
- the orchestrator should read `manifest.json` or `manifest.env` directly
- `response.md` must be read from the declared path, not inferred from temp-directory search results


## 9. Silent Manual Fallback After Blocked Booster

Anti-pattern:

- a blocked `booster` step is followed by manual repo work without clearly ending orchestrator mode first
- the later manual work is narrated as though it were still part of the accepted booster chain

Guardrail:

- a blocked booster cycle must end immediately
- the next legal action is either a fresh orchestrator resume after transport repair or an explicit orchestrator exit
- any manual implementation pass after exit is separate from the orchestrated acceptance chain until workflow orchestration is deliberately re-entered

## 10. Global Tooling Mutation Inside a Feature Run

Anti-pattern:

- the orchestrator edits installed shared skills, transport wrappers, or other global tooling during a feature run in order to keep the current cycle alive

Guardrail:

- treat shared-tool repair as separate maintenance or diagnostics work, not as part of the bounded feature run
- do not mutate `~/.codex/skills/...` assets during the current orchestrated cycle
- after such repair work, restart from a fresh orchestrator run if workflow execution is still needed
