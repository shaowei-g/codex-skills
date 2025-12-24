---
name: typescript-write
description: Write TypeScript and JavaScript code following Metabase coding standards and best practices. Use when developing or refactoring TypeScript/JavaScript code.
---

# TypeScript Write (Metabase Standards)

Use this skill when implementing or refactoring TypeScript/JavaScript in a Metabase codebase (or a codebase that follows Metabase conventions).

## Autonomous Development Workflow

- Do not attempt to read or edit files outside the project folder.
- Add failing tests first, then fix them.
- Work autonomously in small, testable increments.
- Run targeted tests, and lint continuously during development.
- Prioritize understanding existing patterns before implementing.
- Don't commit changes; leave it for the user to review and make commits.

## Implementation Principles

- Prefer using existing Metabase patterns and utilities over inventing new abstractions.
- Keep changes small, focused, and easy to review; avoid drive-by refactors.
- Treat type boundaries explicitly (API responses, `localStorage`, query params, event payloads).
  - Prefer `unknown` at the boundary, then validate/narrow with runtime checks.

## Type Rules

- Avoid `any`. If you must temporarily unblock work, use `unknown` + narrowing and/or a dedicated parsing layer.
- Prefer defining `interface`s over type aliases for object shapes.
- Prefer explicit return types on exported functions and public APIs.
- Avoid widening: keep unions narrow and use discriminated unions when modeling variants.

## Testing

- Prefer the project’s existing test runner and conventions; default to Jest + ts-jest when appropriate.
- Add a failing test that demonstrates the bug/desired behavior before implementing the fix.
- Prefer focused unit tests; add integration/e2e coverage only when the change requires it.

## Linting and Formatting

- **Lint:** `npm run lint --fix`
  - Run ESLint on the codebase and fix issues.
- **Format:** `npm run prettier --write .`
  - Format code using Prettier.
- **Type Check:** `npm run type-check-pure`
  - Run TypeScript type checking.

## Suggested Workflow (Checklist)

1. Identify the closest existing implementation pattern in the codebase (similar module/component/test).
2. Write a failing test (or update an existing one) proving the intended behavior.
3. Implement the smallest fix that makes the test pass while matching existing style.
4. Tighten types (remove broad types, model invariants, validate at boundaries).
5. Run targeted tests, then `npm run lint --fix`, `npm run prettier --write .`, and `npm run type-check-pure`.
