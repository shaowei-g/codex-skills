# Frontend Review Checklist And Report Template

## Checklist

Review the requested code against these categories:

- Code correctness: broken conditions, bad assumptions, missing null handling, unsafe async sequencing, hydration mismatches, and permission bugs
- Performance optimization: repeated heavy transforms, oversized client components, avoidable bundle cost, synchronous work in render, and unnecessary DOM work
- TypeScript type safety: `any`, broad casts, unsafe non-null assertions, mismatched server contracts, and weak form or query typing
- API request efficiency: duplicate requests, cache-key drift, waterfalls, missing dedupe, redundant invalidation, and over-fetching
- State management: duplicated derived state, context churn, mutation risk, race conditions, and hidden cross-feature coupling
- Memory leaks: uncleared timers, listeners, observers, subscriptions, and abandoned async work
- React rendering performance: unstable dependencies, inline closures or objects in hot paths, excessive provider scope, missing list virtualization, and client/server boundary mistakes
- Error handling: swallowed exceptions, silent fallbacks, impossible states, missing loading or empty states, and unhelpful error surfaces
- Code duplication: repeated data transforms, repeated conditional trees, repeated request wrappers, and copy-pasted business rules
- Readability and maintainability: large mixed-responsibility components, unclear naming, dead code, weak abstraction boundaries, and missing tests for risky logic

## Severity Guide

- `Critical`: likely production outage, security problem, data corruption, or a guaranteed broken core flow
- `High`: strong likelihood of user-visible breakage, serious performance regression, or high regression risk
- `Medium`: correctness or maintainability problem with limited blast radius or a recoverable workaround
- `Low`: worthwhile improvement with low immediate product risk

## Report Template

Use this shape for every review:

````md
## Findings

### 1. <Short issue summary>
- Severity: High
- Code location: `packages/eKoEN/src/.../file.tsx:42`
- Root cause: <Explain the concrete mechanism>
- Suggested solution: <Explain the smallest reliable fix>
- Example refactored code:

```tsx
// Short example only. Keep it focused on the fix.
```

### 2. <Short issue summary>
- Severity: Medium
- Code location: `packages/eKoEN/src/.../other.ts:18`
- Root cause: <Explain the concrete mechanism>
- Suggested solution: <Explain the smallest reliable fix>
- Example refactored code:

```ts
// Short example only. Keep it focused on the fix.
```

## Open Questions

- <Only include when a finding depends on an unresolved assumption>

## Residual Risks

- <Note commands not run, flows not covered, or evidence limits>
````

## Report Rules

- Put findings before any summary.
- Order findings from highest to lowest severity.
- Omit sections that are empty except `Residual Risks`, which should always be present.
- Keep example refactors minimal. Show the fix, not a full-file rewrite.
- State explicitly when no findings were found.
