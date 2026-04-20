# SQL Performance Red Flags

Use this file while reviewing backend diffs for database-access cost.

## Quick Search Patterns

Use focused searches before reading large files:

```bash
rg -n "findOne\(|find\(|count\(|populate:|execute\(|nativeUpdate\(|nativeInsert\(|Promise\.all|\.map\(async|for \(|for\.\.of" app
```

Then follow the call chain to see whether the database access sits inside a loop, fan-out path, or repeated request flow.

## High-Signal Anti-Patterns

### 1. N+1 lookup in loop or Promise.all

Example shape:

```ts
await Promise.all(items.map((item) => em.findOne(Entity, { id: item.entityId })))
```

Why it is bad:

- Query count grows with input size.
- Latency and DB load scale linearly.
- Repeated IDs often cause duplicate work.

Preferred pattern:

1. Collect unique IDs.
2. Fetch once with `$in`.
3. Build a map.
4. Read from memory during the loop.

### 2. Repeated metadata lookup across conditions or rules

Watch for rule engines, event processing, and device-binding code that resolves names or labels one condition at a time.

Preferred pattern:

- Pre-collect all foreign keys touched by the batch.
- Load them once with a narrow field list such as `id` and `name`.
- Reuse the result map for the whole request.

### 3. Broad entity hydration for one or two fields

Example shape:

```ts
await em.findOne(Equipment, { id }, { populate: ['organization', 'site', 'children'] })
```

Question to ask:

- Does the caller only need a name, ID, or org ID?

Preferred pattern:

- Use `fields` to limit selected columns.
- Avoid `populate` unless the relation data is truly needed.

### 4. Duplicate reads in the same request path

Common smell:

- `findOne` to check existence, followed by another `findOne` or `find` for the same row.
- Re-resolving the same related entity in multiple helper calls.

Preferred pattern:

- Reuse the first result.
- Pass resolved data downward.
- Cache repeated lookups within the request scope when safe.

### 5. App-side filtering after broad fetch

Common smell:

- Load a large collection into memory and then filter, sort, or dedupe in TypeScript.

Preferred pattern:

- Push filtering, sorting, limits, and aggregation into ORM conditions or query builder clauses.

### 6. Raw SQL in runtime code

The repo constitution forbids direct SQL strings in `app/` runtime code unless explicitly approved.

Flag:

- `em.execute('...')`
- `em.getConnection().execute('...')`
- String-built SQL in services, controllers, or use cases

Preferred pattern:

- MikroORM `find`, `count`, `native*`, or query builder.
- Parameterized abstractions rather than interpolated SQL.

## Severity Hints

- `Critical`: query explosion on a hot path or request path that will run for every page load or event.
- `High`: clear N+1, repeated metadata fetches, or broad hydration in a path that can grow with input size.
- `Medium`: unnecessary extra reads, weak field selection, or app-side filtering with moderate scale risk.
- `Low`: likely harmless today but inconsistent with safe scaling patterns.
