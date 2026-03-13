---
name: ekoen-frontend-code-review
description: Production-grade code review for the eKoEN frontend codebase. Use when asked to review, audit, inspect, or harden eKoEN React/Next.js frontend code, pages, components, hooks, API clients, or state layers for bugs, performance bottlenecks, TypeScript safety issues, request inefficiency, state-management risks, memory leaks, rendering regressions, error-handling gaps, duplication, or maintainability problems, especially when a structured severity-ranked report with code locations, root causes, suggested fixes, and example refactors is required.
---

# eKoEN Frontend Code Review

## Overview

Act as a senior frontend engineer performing a production review. Prefer concrete, user-impacting findings over stylistic suggestions, and keep the report focused on correctness, performance, resilience, and maintainability.

## Log First And Last

Call the usage logger once before returning a final answer:

```bash
~/.codex/skills/skill-usage-logger/scripts/log_skill_usage.sh \
  --skill "ekoen-frontend-code-review" \
  --status "success" \
  --meta '{"target":"ekoen-frontend-review"}'
```

If the review aborts because of a tool failure, blocked file, or conflicting workspace state, log the error with `--status error` and record the underlying diagnostic with:

```bash
~/.codex/skills/diag-log/scripts/log_diag_event.sh \
  --event-type "error" \
  --source "skill" \
  --name "ekoen-frontend-code-review" \
  --message "<short failure summary>" \
  --meta '{"step":"<review-step>"}'
```

## Review Workflow

1. Define the scope from the user request.
2. Inspect the current repo layout, package boundaries, and changed files before judging implementation details.
3. Read [references/repo-layout.md](references/repo-layout.md) when the target is the eKoEN monorepo so you start in the right packages and use the right commands.
4. Read [references/review-checklist.md](references/review-checklist.md) before writing findings so the review stays aligned with the required categories and report shape.
5. Gather evidence from source files, related types, hooks, tests, API callers, and state containers. Follow data flow instead of reviewing a file in isolation.
6. Run cheap validation commands when they help confirm impact. Prefer targeted commands over broad ones, and never claim a command ran if it did not.
7. Report findings ordered by severity. Put findings first. Keep summaries brief.

## Review Priorities

Prioritize these classes of issues:

- Broken or fragile behavior in user flows, state transitions, permissions, or data mapping
- Performance regressions caused by repeated rendering, expensive calculations, large client bundles, or duplicated network traffic
- TypeScript unsafety such as `any`, unchecked casts, nullable hazards, mismatched API contracts, and inferred `unknown` values used unsafely
- Request inefficiency such as duplicate fetches, missing cache keys, stale invalidation logic, unnecessary waterfalls, and over-fetching
- State management problems such as derived state drift, stale closures, mutation bugs, race conditions, and global state coupling
- Memory leaks from uncleared timers, subscriptions, observers, or event listeners
- React rendering issues such as unstable props, context over-rendering, client/server boundary mistakes, or unnecessary client components
- Missing or weak error handling, especially swallowed errors, impossible states, and missing loading, empty, or retry states
- Code duplication that increases regression risk
- Readability and maintainability issues that materially slow safe changes

## Validate Findings

Only report issues you can support with code evidence. Avoid speculative comments such as "might be slow" unless you can point to the mechanism and likely impact.

For each finding:

1. Point to the exact file and line.
2. Explain the concrete failure mode or regression risk.
3. State why it happens.
4. Suggest the smallest fix that aligns with surrounding patterns.
5. Include a short refactored code example when it improves clarity.

If you do not find any actionable issues, say so explicitly and mention residual risks such as untested flows, missing benchmarks, or commands you did not run.

## Investigation Heuristics

Use these heuristics while tracing the code:

- Follow fetchers through API wrappers, React Query hooks, server actions, and consuming components to spot duplicate requests and cache misses.
- Check `useEffect`, subscriptions, timers, `IntersectionObserver`, `ResizeObserver`, and DOM listeners for missing cleanup or unstable dependencies.
- Check list rendering, large tables, charts, and dashboards for repeated transformations, inline object creation, and unnecessary client-side work.
- Compare component props and context values to see whether a broad provider is forcing subtree rerenders.
- Inspect type definitions near API boundaries and form parsing code for unsafe narrowing or data coercion.
- Confirm error paths handle rejected promises, partial data, and permission failures.
- Treat duplicated business logic across pages, hooks, and helpers as a maintainability bug when it can diverge.

## Output Requirements

Produce a structured Markdown report that includes:

- `Issue summary`
- `Severity` as `Low`, `Medium`, `High`, or `Critical`
- `Code location`
- `Root cause`
- `Suggested solution`
- `Example refactored code`

Use the report template in [references/review-checklist.md](references/review-checklist.md). Keep code examples short, compilable in spirit, and consistent with local conventions.
