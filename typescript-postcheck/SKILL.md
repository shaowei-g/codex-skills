---

name: typescript-postcheck
description: Run post-implementation quality gates for TypeScript/JavaScript: type-checking, linting, and tests. Use after finishing an implementation or refactor to validate correctness and produce actionable diagnostics + minimal fixes.

---

# TypeScript Post-Implementation Check (Agent Skill)

Use this skill **after implementation/refactoring is complete** to ensure the codebase passes the core quality gates: **TypeScript type checking, linting, and tests**. Convert failures into **actionable, minimal fix steps** and re-run gates until everything passes.

> **Writing rules reference:** Follow the code-writing conventions and standards defined in `skills/typescript-write/SKILL.md`.

## When to Use

- Right after finishing a feature implementation, before opening a PR
- After refactoring, to ensure no type boundary regressions
- After bug fixes, to confirm no new TS/lint/test failures
- When CI fails and you need a local/agent triage + fix loop

---

## Autonomous Verification Workflow

- Do not read or modify files outside the project folder.
- Work autonomously in small, verifiable increments.
- Prefer targeted checks first, then full checks.
- Do not commit changes; leave commits to the user after review.
- After every fix, re-run the relevant gate(s) to confirm progress.
- When proposing or applying code changes, follow the writing rules in `skills/typescript-write/SKILL.md`.

---

## Gate Order (Fast → Slow)

1. **Type Check (required)**
2. **Lint (required)**
3. **Targeted Tests (required for touched areas)**
4. _(Optional)_ **Build/Bundle** (if the repo requires it)

Rationale: type errors often cascade; fix the compilation surface first, then style rules, then behavior.

---

## Default Commands (Prefer Repo Scripts)

Always prefer existing repo scripts; only fall back when missing.

### 1) Type Check (primary)

- `npm run typecheck`
- `pnpm -s run typecheck`
- `yarn -s typecheck`
- `npm run type-check-pure` _(if the repo uses this naming)_

### 2) Lint

- `npm run lint`
- `npm run lint -- --fix` _(or repo-specific flagging)_

### 3) Tests

- `npm test`
- Targeted: `npm test -- <pattern>` / `jest <pattern>` _(per repo conventions)_

### 4) Fallback Type Check (if no script exists)

- `npx tsc -p tsconfig.json --noEmit` _(or repo-specific tsconfig path)_

---

## Diagnostics Triage Strategy

When a gate fails:

1. **Classify failures**
   - TypeScript: `TSxxxx`, incompatible types, missing properties, implicit any, etc.
   - ESLint: rule violations, unused vars, `no-floating-promises`, etc.
   - Tests: assertion failures, timeouts, mocks not aligned

2. **Fix upstream blockers first**
   - Fix the first/root TypeScript error before chasing cascades.
   - If multiple errors in one file: prioritize type declarations, exported APIs, return types, and generic constraints.

3. **Minimal diffs**
   - Avoid drive-by refactors.
   - Avoid new abstractions unless they clearly reduce repetition and improve correctness.
   - Avoid `any`; use `unknown` + narrowing or a dedicated parsing layer if needed.
   - Ensure all code changes adhere to `skills/typescript-write/SKILL.md`.

4. **Re-run gates**
   - After each fix, re-run the same gate.
   - Only proceed to the next gate when the current gate passes.

---

## Required Output Format (Deliverable)

Each run of this skill must output:

1. **Commands executed** (with pass/fail)

2. **Failure summary**:
   - Top 3–10 most relevant diagnostics per gate (include file, line/col, TS code / ESLint rule)

3. **Fix plan**: an ordered, minimal step list

4. _(If allowed to edit code)_ **Minimal patch** addressing only what is necessary, following `skills/typescript-write/SKILL.md`

5. **Re-run results**: until all gates pass or a clear external blocker is identified (missing deps, environment mismatch, etc.)

---

## Suggested Checklist

1. Run `typecheck` (or repo-specific type-check script)
2. Fix until typecheck passes
3. Run `lint` (use `--fix` if appropriate)
4. Run targeted tests covering touched paths
5. Confirm all gates pass
