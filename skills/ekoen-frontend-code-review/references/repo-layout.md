# eKoEN Repo Layout

Use this reference when the target is the `ekoen-rebuild` monorepo.

## Primary Packages

- `packages/eKoEN`: main frontend application. Expect most review work here.
- `packages/eKoEN-split`: secondary frontend package. Review it when the request mentions split flows or files under this package.

## High-Signal Areas In `packages/eKoEN`

- `src/app`: Next.js App Router entrypoints, layouts, pages, and route-level boundaries
- `src/components` and `src/components-global`: reusable UI, composite feature components, and often-rendered trees
- `src/hooks`: shared hooks where request duplication, stale closures, and cleanup bugs often appear
- `src/api` and `src/server-action`: request orchestration, caching, transforms, and boundary typing
- `src/contexts`: global providers that can trigger broad rerenders or state coupling
- `src/utils`, `src/helpers`, `src/models`, and `src/types`: shared logic and type contracts worth checking when behavior looks suspicious
- `src/__test__`: useful for verifying intended behavior and coverage gaps

## Useful Commands

Run commands from the package directory that matches the files under review.

### `packages/eKoEN`

```bash
pnpm --dir packages/eKoEN lint
pnpm --dir packages/eKoEN typecheck
pnpm --dir packages/eKoEN test -- --runInBand
```

### `packages/eKoEN-split`

```bash
pnpm --dir packages/eKoEN-split lint
pnpm --dir packages/eKoEN-split build
```

## Discovery Tips

- Start with `git status` and `git diff --stat` when the request is about current changes.
- Use `rg` to trace component names, hook names, query keys, and API helpers across package boundaries.
- Read nearby tests, types, and server helpers before concluding a pattern is wrong.
