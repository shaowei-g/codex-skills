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
  - e.g. parsing API responses, `JSON.parse(localStorage.getItem(...))`, or `URLSearchParams`

## Type Rules

- Avoid `any`. If you must temporarily unblock work, use `unknown` + narrowing and/or a dedicated parsing layer.
- Prefer defining `interface`s over type aliases for object shapes.
- Prefer explicit return types on exported functions and public APIs.
- Avoid widening: keep unions narrow and use discriminated unions when modeling variants.

## State & Side Effects

- Prefer colocating state as close as possible to where it is used.
- Avoid introducing new global state unless absolutely necessary.
- Keep side effects (data fetching, subscriptions, mutations) explicit and isolated.
- Avoid hidden side effects inside utility functions.
  - e.g. a helper that triggers a network request or mutates global state

## Testing

- Prefer the project’s existing test runner and conventions; default to Jest + ts-jest when appropriate.
- Add a failing test that demonstrates the bug/desired behavior before implementing the fix.
- Prefer focused unit tests; add integration/e2e coverage only when the change requires it.

## Comments & Documentation

- Prefer self-documenting code over comments.
- Add comments only when explaining non-obvious intent or trade-offs.
- Avoid comments that restate what the code already says.

## Anti-Patterns to Avoid

- Introducing new abstractions without strong reuse justification.
  - e.g. generic helpers created "for future use" with only one caller
- Over-generalizing types or utilities "for future use".
- Large, unrelated changes in a single diff.

## Linting and Formatting

- **Lint:** `npm run lint --fix`
  - Run ESLint on the codebase and fix issues.
- **Format:** `npm run prettier --write .`
  - Format code using Prettier.
- **Type Check:** `npm run type-check-pure`
  - Run TypeScript type checking.

- **Code Organization & Structure**

- All exported functions (including the main entry function) must be defined at the top of the file.
- Helper functions should be defined as close as possible to where they are used.
- Do not place all helper functions at the bottom of the file by default.
- Prefer local proximity over grouping helpers together.

## Suggested Workflow (Checklist)

1. Identify the closest existing implementation pattern in the codebase (similar module/component/test).
2. Write a failing test (or update an existing one) proving the intended behavior.
3. Implement the smallest fix that makes the test pass while matching existing style.
4. Tighten types (remove broad types, model invariants, validate at boundaries).
5. Run targeted tests, then `npm run lint --fix`, `npm run prettier --write .`, and `npm run type-check-pure`.
