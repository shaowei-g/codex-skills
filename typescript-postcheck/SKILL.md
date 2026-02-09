---
name: typescript-postcheck
description: "Run post-implementation quality gates for TypeScript/JavaScript projects: type checking, linting, targeted tests, and optional build checks. Use after implementing, refactoring, or fixing bugs to validate changes, triage failures, apply minimal fixes, and report command-by-command results."
---

# TypeScript Postcheck

Run this skill after code changes are complete to verify quality gates and produce a concise remediation loop.

## Workflow

1. Detect package manager and available scripts from `package.json`.
2. Run checks in this order:
   - type check
   - lint
   - targeted tests for touched areas
   - optional build check when required by the repo
3. Stop on the first failing gate.
4. Classify failures by root cause.
5. Apply the smallest safe fix.
6. Re-run only the failed gate, then continue the sequence.
7. Repeat until all required gates pass or an external blocker is confirmed.

## Command Strategy

Prefer repo scripts first; use fallbacks only if scripts are missing.

- Type check: `typecheck`, `type-check`, or `tsc --noEmit`
- Lint: `lint` (optionally with `--fix`)
- Test: `test` with path/pattern targeting when possible
- Build (optional): `build`

Use `scripts/run_postcheck.sh` to run the sequence consistently.

## Fix Rules

- Fix root causes before cascaded errors.
- Keep diffs minimal and local to the failing scope.
- Avoid `any`; use narrowing or explicit interfaces.
- Avoid unrelated refactors while unblocking checks.
- Re-run the relevant gate after each fix.

## Output Contract

Always return:

1. Commands run with pass/fail status.
2. Top diagnostics per failing gate (file and line).
3. Ordered minimal fix plan.
4. Re-run results and final gate status.
5. External blockers, if any (missing deps, env mismatch, CI-only conditions).

## Resources

### scripts/

- `run_postcheck.sh`: Detect package manager, run gates in order, and emit a readable summary.
