---
name: typescript-write
description: Write TypeScript and JavaScript code following Metabase coding standards and best practices. Use when developing or refactoring TypeScript/JavaScript code.
---

# TypeScript Write (Metabase Standards)

Use this skill when implementing or refactoring TypeScript/JavaScript in a Metabase codebase (or a codebase that follows Metabase conventions).

## Autonomous Development Workflow

- Do not attempt to read or edit files outside the project folder.
- **Before writing code, search the codebase for existing implementations to reuse** (components, hooks, utilities, patterns, tests).
- Add failing tests first, then fix them.
- Work autonomously in small, testable increments.
- Run targeted tests, and lint continuously during development.
- Prioritize understanding existing patterns before implementing.
- Don't commit changes; leave it for the user to review and make commits.
- After implementation is complete (tests passing), run **typescript-postcheck** skill and address any findings before finalizing.

## Reuse-First Principle (Must Follow)

Before creating new code, **attempt reuse in this order**:

1. **Existing component/module** that already matches the UI/behavior (frontend: components first).
2. **Existing hook/utility** that provides the same data transformation or side-effect handling.
3. **Existing pattern** in a similar feature area (copy the shape, not the whole file).
4. Only if no suitable option exists: create a **minimal, single-purpose** implementation consistent with existing patterns.

Guidelines:

- Prefer **extension/composition** over duplication (e.g., add a prop/option, wrap component, or extract a helper already used elsewhere).
- Do not introduce “general-purpose” abstractions for hypothetical future use.
- When reuse is not possible, explicitly state _why_ (API mismatch, missing variant, performance constraints, coupling, etc.) and then implement the smallest new code.

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
- Creating a new component when an existing one can be extended or composed.

## Linting and Formatting

- **Lint:** `npm run lint --fix`
  - Run ESLint on the codebase and fix issues.

- **Format:** `npm run prettier --write .`
  - Format code using Prettier.

- **Type Check:** `npm run type-check-pure`
  - Run TypeScript type checking.

- Prefer running these via **typescript-postcheck** after implementation so checks are executed consistently and in the expected order.

## Code Organization & Structure

- All exported functions (including the main entry function) must be defined at the top of the file.
- Helper functions should be defined as close as possible to where they are used.
- Do not place all helper functions at the bottom of the file by default.
- Prefer local proximity over grouping helpers together.

## Suggested Workflow (Checklist)

1. Identify the closest existing implementation pattern in the codebase (similar module/component/test).
2. **Search for reusable code first**:
   - Frontend: existing components (same UX), then hooks, then utilities.
   - Backend: existing services/handlers, then shared libs, then utilities.

3. Write a failing test (or update an existing one) proving the intended behavior.
4. Implement the smallest fix that makes the test pass while matching existing style.
5. Tighten types (remove broad types, model invariants, validate at boundaries).
6. Run targeted tests.
7. Run **typescript-postcheck** skill.
8. If postcheck reports issues, fix them, rerun relevant tests, then rerun **typescript-postcheck** until clean.
