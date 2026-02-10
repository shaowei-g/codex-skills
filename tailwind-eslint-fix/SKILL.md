---
name: tailwind-eslint-fix
description: Auto-fix and verify ESLint better-tailwindcss warnings/errors in frontend files. Use after implementing or refactoring TSX/JSX/frontend code (React, Next.js, Tailwind) when you need to clean up Tailwind class order, canonical class forms, shorthand classes, and line-wrapping warnings.
---

# Tailwind ESLint Fix

## Overview

Use this skill after frontend implementation or refactoring to resolve `better-tailwindcss/*` lint issues quickly and consistently.
It runs ESLint auto-fix on the target scope, then checks whether any `better-tailwindcss` warnings/errors still remain.

## Workflow

1. Choose scope:

- Default scope: all frontend source files (`src/**/*.{ts,tsx,js,jsx}`).
- Preferred scope: only changed files/directories to keep edits focused.

2. Run the fixer script:

```bash
~/.codex/skills/tailwind-eslint-fix/scripts/fix_better_tailwind.sh \
  --project-dir <frontend-package-dir> \
  --pm <auto|pnpm|yarn|npm> \
  --target "<eslint-glob-or-file-list>"
```

3. Review results:

- If script reports no remaining `better-tailwindcss` issues: done.
- If issues remain: fix manually, then rerun script until clean.

4. Keep scope strict:

- Do not treat unrelated eslint rules as part of this skill's success criteria.
- This skill targets only `better-tailwindcss` warnings/errors.

## Quick Commands

Fix whole frontend package:

```bash
~/.codex/skills/tailwind-eslint-fix/scripts/fix_better_tailwind.sh \
  --project-dir packages/eKoEN \
  --pm auto
```

Force `yarn`:

```bash
~/.codex/skills/tailwind-eslint-fix/scripts/fix_better_tailwind.sh \
  --project-dir packages/eKoEN \
  --pm yarn
```

Force `npm`:

```bash
~/.codex/skills/tailwind-eslint-fix/scripts/fix_better_tailwind.sh \
  --project-dir packages/eKoEN \
  --pm npm
```

Fix specific directory:

```bash
~/.codex/skills/tailwind-eslint-fix/scripts/fix_better_tailwind.sh \
  --project-dir packages/eKoEN \
  --pm auto \
  --target "src/RefactorComponents/**/*.{ts,tsx}"
```

Fix specific files:

```bash
~/.codex/skills/tailwind-eslint-fix/scripts/fix_better_tailwind.sh \
  --project-dir packages/eKoEN \
  --pm auto \
  --target "src/components/LanguageSelector.tsx src/RefactorComponents/Selects/SelectButton/SingleValue.tsx"
```

## Notes

- This skill supports `pnpm`, `yarn`, and `npm`.
- Use `--pm auto` to detect by lockfile (`pnpm-lock.yaml`, `yarn.lock`, `package-lock.json`) or available command.

## Resources

### scripts/

- `fix_better_tailwind.sh`: runs eslint `--fix` on a target scope and verifies remaining `better-tailwindcss` findings.
