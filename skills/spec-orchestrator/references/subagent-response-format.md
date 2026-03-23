# Subagent Response Format

Every subagent must return results using this exact section order, headings, and allowed values.
Any output outside this contract is invalid until repaired or replaced by the orchestrator.

The schema stays compact. The orchestrator can read the delegated response directly, so supporting detail still lives in one freeform `Result` section. The only added field is `Artifacts`, which carries repo-write payloads when delegated transport can read but cannot persist files safely.

~~~markdown
Status:

- completed | blocked | rejected

Feature-Slug:

- <feature-slug>

Assigned-Phase:

- inspection | specification | planning | task decomposition | implementation | verification | drift check | handoff

Assigned-Subagent:

- spec-viewer | spec-analyst | spec-planner | spec-tasker | spec-implementer | spec-verifier | spec-drift-check | spec-handoff

Scope:

- <single assigned scope>

Result:

- none | <succinct durable outcome, blockers, evidence, drift, and file notes as needed>

Artifacts:

- none

or one or more fenced artifact blocks:

```artifact path="specs/<feature>/plan.md"
<full file content>
```

Recommended-Next-Phase:

- inspection | specification | planning | task decomposition | implementation | verification | drift check | handoff | none

Recommended-Next-Subagent:

- spec-viewer | spec-analyst | spec-planner | spec-tasker | spec-implementer | spec-verifier | spec-drift-check | spec-handoff | none

Self-Check:

- one_bounded_scope = true
- assigned_phase_only = true
- chose_next_phase = false
- chose_next_subagent = false
- unauthorized_handoff = false
- outside_ownership_modification = false
- required_response_schema_used = true
- terminating_now = true
~~~

## Field Rules

- The approved response contains exactly 10 headings in the documented order and no extras.
- `Status` is required and must be one of `completed`, `blocked`, or `rejected`.
- `Feature-Slug` is required and must contain exactly one feature slug.
- `Assigned-Phase` is required and must name the assigned phase only.
- `Assigned-Subagent` is required and must name exactly one approved subagent.
- `Scope` is required and must describe exactly one bounded assignment.
- `Result` is the single narrative payload field for durable work completed in this run, relevant files touched or read, blockers, missing prerequisites, contract problems, unresolved questions, drift findings, evidence, and concise notes when those details matter.
- `Artifacts` is the single machine-materialization field.
- `Artifacts` must be either:
  - `- none`
  - or one or more fenced blocks whose info string begins with `artifact` and includes exactly one repo-relative `path="..."` attribute
- `Artifacts` blocks are authoritative file payloads for orchestrator-side materialization. They are not commentary.
- `Recommended-Next-Phase` contains at most one advisory next-step recommendation for the orchestrator.
- `Recommended-Next-Subagent` contains at most one advisory next-subagent recommendation from the approved enum set for the orchestrator.
- `Self-Check` is required and must keep all rule flags explicit.

## Writing Rule for `Result`

- Keep it compact and truthful.
- Include only details that materially help the orchestrator decide acceptance or the next bounded step.
- Use bullets or short paragraphs freely inside `Result`; the validator only fixes the outer schema, not the prose style.
- Do not create fake structure inside `Result` that implies routing authority or extra phases.

## Writing Rule for `Artifacts`

- Use `Artifacts` only for repo-owned durable outputs from the assigned phase.
- Prefer direct repo writes when the delegated environment can perform them safely.
- When delegated transport cannot persist files safely but the final artifact content is ready, return `completed` with artifact payload blocks instead of falsely claiming repo writes that did not happen.
- Use repo-relative paths only. Do not emit absolute paths, `..`, or paths outside the target repository.
- For blocked or rejected runs, `Artifacts` should be `- none`.
- Do not mix commentary lines with artifact payload blocks in the `Artifacts` section.

## Machine Validation Rules

- Use `bash ../scripts/validate_subagent_response.sh` to validate heading count, heading order, delegated identity, enum values, feature slug, scope, artifact-section shape, and self-check lines.
- Always invoke the validator as `bash <script>` instead of relying on an executable bit.
- Use `../scripts/print_subagent_response_schema.sh` to print the approved fixed template when the orchestrator needs a controlled replacement record.
- Use `bash ../scripts/materialize_response_artifacts.sh` when the orchestrator needs to write response-embedded artifact payloads into the repository.
- Missing headings, extra headings, heading order mismatches, invalid enum values, malformed artifact blocks, incomplete self-check lines, or delegated identity mismatches are validator failures.
- The orchestrator may allow one repair pass only for format-only defects.
- A repair pass may not add new analysis, change the assigned scope, change claimed durable work, or alter the delegated phase/subagent identity.
- Semantic violations such as cross-phase work, ownership violations, undeclared file changes, routing override attempts, or repeated malformed output must be rejected, not normalized.

## Interpretation Rules

- `completed` means the assigned single-phase scope is complete either because the repo was written directly in the delegated run or because the response contains complete artifact payloads that the orchestrator can materialize truthfully.
- `blocked` means the assigned scope is still the correct one but cannot be completed safely yet.
- `rejected` means the assignment itself was invalid for the specialist.
- The `Artifacts` section does not transfer routing authority, acceptance authority, or cross-phase authority to the specialist.
