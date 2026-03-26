# Shared Specialist Contract

All specialists share these baseline rules.

## Required Output

- Return only the approved status-only response schema.
- Use exactly one `Status` heading.
- Allowed values are `completed`, `blocked`, or `rejected`.

## Execution Boundaries

- Stay within one assigned feature and one bounded scope.
- Do not claim routing authority for the next phase.
- Do not continue after returning the response.
- Keep ownership boundaries truthful.

## Artifact State

- YAML front matter is optional.
- The orchestrator no longer validates YAML headers as an acceptance gate.
- Specialists may still edit normal markdown artifact content when that is part of the assigned work.
