---
name: conventional-commit-helper
description: Generate and validate Conventional Commit messages for semantic-release workflows. Use when a user asks to write a commit message, asks to commit changes, asks for commit type/scope selection, or asks to enforce Conventional Commits consistency.
---

# Conventional Commit Helper

## Overview

Create readable, semantic-release friendly commit messages with consistent type/scope/subject formatting. Support message drafting, validation, and optional non-interactive git commit execution.

## Workflow

1. Inspect changes with `git status --short` and `git diff --cached --name-only`.
2. Select `type` from the allowed set:
   - `feat`, `fix`, `perf`, `revert`, `docs`, `style`, `refactor`, `test`, `build`, `ci`, `chore`
3. Infer `scope` from affected module/path (examples: `api`, `auth`, `db`, `service`, `config`, `deps`, `ci`, `docs`, `test`).
4. Draft subject:
   - imperative/present tense (`add`, `fix`, `update`, `remove`)
   - lowercase
   - no trailing period
   - prefer <= 50 chars
5. Add body bullets for what/why if needed.
6. Add footer for issue refs or breaking changes.
7. Validate message using `scripts/validate_commit_message.sh`.
8. If requested, commit with non-interactive git commands only.

## Message Template

```text
<type>(<scope>): <subject>

[optional body]

[optional footer]
```

## Breaking Change Rules

Use either:
- `type(scope)!: subject`
- `BREAKING CHANGE:` footer

## Resources

- Detailed guidance and examples: `references/commit-conventions.md`
- Message validator: `scripts/validate_commit_message.sh`

## Commands

Validate a message string:

```bash
./scripts/validate_commit_message.sh --message "fix(auth): reject expired refresh token"
```

Validate a message file:

```bash
./scripts/validate_commit_message.sh --file .git/COMMIT_EDITMSG
```
