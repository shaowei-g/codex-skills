# Subagent Response Format

Every subagent must return results using this exact section order and headings.

```markdown
Status:

- completed | blocked | rejected

Feature:

- <feature-slug>

Scope:

- <single assigned scope>

Completed:

- none | <durable work completed>

Files:

- none | <path>

Blockers:

- none | <blocking issue>

Unresolved Questions:

- none | <question>

Drift:

- none | <drift finding>

Evidence:

- none | <tests run, checks performed, or reason not run>

Recommended Next Phase:

- specification | planning | task decomposition | implementation | verification | drift check | handoff
```

## Field Rules

- `Status` is required and must be one of `completed`, `blocked`, or `rejected`.
- `Feature` is required and must contain exactly one feature slug.
- `Scope` is required and must describe exactly one bounded assignment.
- `Completed` lists only durable work actually finished in this run.
- `Files` lists created or updated files; use `none` when no safe file update occurred.
- `Blockers` lists only issues that prevent completion of the assigned scope.
- `Unresolved Questions` lists non-blocking unknowns that remain relevant.
- `Drift` records in-scope confirmation or drift discovery; use `none` when absent.
- `Evidence` states what was checked, tested, or intentionally not tested.
- `Recommended Next Phase` contains exactly one next-step recommendation for the orchestrator.

## Interpretation Rules

- `completed` means the assigned single scope is done and ready for orchestration review.
- `blocked` means the subagent stopped because the scope could not be safely completed.
- `rejected` means the request violated entry gate, single-scope, or phase-boundary rules.
