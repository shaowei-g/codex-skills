# Subagent Response Format

All specialists now return the same minimal response shape.

## Required Schema

```md
Status:

- completed
```

Allowed status values:

- `completed`
- `blocked`
- `rejected`

## Rules

- `Status` is the only required response field.
- Do not add `Feature-Slug`, `Assigned-Phase`, `Assigned-Subagent`, `Scope`, `Result`, `Artifacts`, recommendation fields, or `Self-Check`.
- The shared validator checks only the outer `Status` heading and the status enum.
- Use `../scripts/print_subagent_response_schema.sh` to print the fixed template.

## Validation

Validate with:

```bash
bash ./scripts/validate_subagent_response.sh --file /abs/path/to/response.md
```
