---
name: nextjs-write
description: Write or refactor Next.js (TypeScript/React) code using Next.js best practices with reuse-first implementation. Use when implementing frontend pages/components/features in Next.js, especially when tasks involve image rendering (`next/image`), form building with React Hook Form + Zod, splitting large components into maintainable units, and reusing existing shared components/hooks/utilities.
---

# Next.js Write (Reuse-First, Maintainable, RHF + Zod)

Use this skill when implementing or refactoring Next.js (TypeScript/React) code in a TypeScript/React codebase.

## Core Requirements (Must Follow)

- Use `next/image` (`<Image />`) for rendering images.
- Reuse existing code before creating anything new:
  - Functional components (FCs)
  - Hooks
  - Utilities and constants
  - UI primitives
  - Prioritize `global/`, `shared/`, `components/`, `ui/`, `hooks/`, `lib/`, `utils/`
- Keep FCs small and single-responsibility:
  - Split large components into `XxxSection`, `XxxForm`, `XxxField`, `XxxList`, `XxxItem`.
  - Keep helper functions near usage.
- Build forms with React Hook Form + Zod by default:
  - Use `zodResolver` from `@hookform/resolvers/zod`.

## Autonomous Development Workflow

- Do not read or edit files outside the project folder.
- Work autonomously in small, testable increments.
- Understand existing routing, data fetching, and UI patterns before implementing.
- Do not commit changes.
- After implementation, run project checks in expected order. If available, use `typescript-postcheck`.

## Reuse-First Search Strategy (Required)

Before creating new code:

1. Find an existing component matching UX/layout.
2. Find an existing hook matching state/data/side-effect needs.
3. Find existing utilities for parsing, formatting, API calls, and error handling.
4. Create the smallest possible new code only when reuse is not viable.

When reuse is not possible, state the reason clearly:
- API mismatch
- Missing variant
- Coupling constraints
- Performance constraints

## Next.js Conventions

### Routing and Rendering

- Prefer Server Components for data fetching and composition when using App Router.
- Use Client Components only when needed (state, effects, handlers, RHF).
- Keep server/client boundaries explicit (`"use client"` only where required).

### Data Fetching

- Reuse existing fetch wrappers from `lib/api`, `services`, or `client` when present.
- Avoid ad-hoc fetch logic in multiple components.
- Handle loading and error states consistently with existing patterns.

### Images

- Always:
  - `import Image from "next/image";`
  - Provide `alt`
  - Provide `width`/`height` or use `fill` with a sized parent
  - Provide `sizes` for responsive layouts when applicable

## React Component Style (Maintainable FCs)

- Keep components small and focused.
- Use `Props` interfaces.
- Use early returns for empty/error states.
- Avoid deeply nested JSX; extract subcomponents.
- Colocate state with the smallest responsible owner.

## Forms (React Hook Form + Zod First)

When building forms:

1. Define or reuse a Zod schema near the form.
2. Infer types with `type FormValues = z.infer<typeof schema>`.
3. Use `useForm<FormValues>({ resolver: zodResolver(schema), defaultValues })`.
4. Use `FormProvider` and small field components when readability improves.
5. Use `Controller` only for non-native/custom inputs.

Required Zod practices:
- Reuse schemas from `global/` or `shared/` when available.
- Keep schemas narrow and aligned with real constraints.
- Prefer `.trim()`, `.min()`, `.max()`, `.email()`, and explicit messages.
- Validate at boundaries (for example API payloads), not only in UI.

Typical structure:
- `XxxForm` owns schema, `useForm`, submit
- `XxxFields` groups field layouts
- `XxxField` encapsulates single reusable field

## Anti-Patterns to Avoid

- Avoid `<img>` instead of `next/image`.
- Avoid duplicating existing shared/global components/hooks/schemas.
- Avoid large multi-responsibility "God components."
- Avoid speculative abstractions with one caller.
- Avoid hand-rolled validation when RHF + Zod is available.

## Suggested Workflow (Checklist)

1. Identify the closest existing page/component pattern.
2. Search shared/global directories for reusable FCs/hooks/utils/schemas.
3. Implement the smallest change using small components.
4. Use RHF + Zod for forms by default.
5. Ensure all images use `next/image`.
6. Run targeted checks/tests, then lint/typecheck per repo convention.
7. Keep diffs focused and reviewable.

## Output Expectations

- Mention which components/hooks/utils/schemas were reused and from where.
- Keep new components small and clearly named.
- Use `next/image` for all image rendering.
- Use React Hook Form + Zod validation by default for forms.
