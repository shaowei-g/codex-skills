# Subagent Reinjection Contract

This reference defines the compact delegated prompt contract and the semantic authority checks that `spec-orchestrator` should enforce.

Execution order lives in `./subagent-lifecycle.md`.

## Compact Delegation Rule

- prefer required fields plus path references
- reference shared contracts instead of restating them inline
- restate only run-specific values that referenced files cannot infer
- keep delegated prompts short enough to scan quickly

## Required Delegated Fields

Every delegated run should still make these values explicit in the prompt:

- Feature-Slug
- Artifact-Directory
- Earliest-Unresolved-Phase
- Assigned-Phase
- Assigned-Subagent
- Scope
- Specialist-Skill
- Repository-Prompt
- Allowed-Ownership
- Forbidden-Artifact-Updates
- Response-Schema
- Response-Validator
- Stop-After-Return

The delegated response payload itself is now status-only.

## Authority and Ownership Checks

A delegated subagent must remain within the assigned feature, phase intent, scope, and ownership set.

A delegated subagent must not:

- choose the next phase
- choose the next subagent
- perform unauthorized handoff
- perform cross-phase execution
- continue implicitly after return
- modify files outside the allowed ownership set

## Response Rule

The only required delegated response field is:

- `Status`

Allowed values:

- `completed`
- `blocked`
- `rejected`

## Related References

- lifecycle sequence: `./subagent-lifecycle.md`
- fallback and repair: `./orchestrator-fallback.md`
- external Codex CLI transport skill: `../../codex-cli-subagent-transport/references/manifest-based-run-contract.md`
- anti-pattern guardrails: `./orchestrator-anti-patterns.md`
- response schema: `./subagent-response-format.md`
