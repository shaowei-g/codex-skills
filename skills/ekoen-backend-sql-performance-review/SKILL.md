---
name: ekoen-backend-sql-performance-review
description: Review skill for eKoEN backend database-access performance. Use when asked to review, audit, inspect, or harden TypeScript backend changes that touch MikroORM, repositories, services, controllers, cron jobs, or SQL-facing logic, especially to catch N+1 queries, per-item lookups inside loops, repeated findOne/find patterns, wasteful hydration, duplicate reads, broad populate usage, app-side filtering of large result sets, or raw SQL escapes before merge.
---

# eKoEN Backend SQL Performance Review

## Overview

Act as a backend reviewer focused on database access cost. Prefer concrete query-count, latency, memory, and load risks over style feedback, and keep findings tied to code evidence.

## Review Workflow

1. Define the scope from the user request and changed files.
2. Read `.specify/memory/constitution.md` when working in the eKoEN backend so the review respects brownfield constraints and the runtime raw-SQL restriction.
3. Read [references/red-flags.md](references/red-flags.md) before writing findings.
4. Trace the full data path from caller to ORM boundary. Do not review a single helper in isolation when it sits inside a loop or hot path.
5. Prefer targeted searches and cheap validation commands over broad exploration. Typical search targets are `findOne`, `find`, `count`, `populate`, `Promise.all`, `.map(async`, `for (` and `execute(`.
6. Report findings ordered by severity. Findings come first. Summary stays brief.

## Prioritize These Problems

- N+1 reads caused by ORM calls inside loops, `Promise.all`, or nested mapping.
- Repeated lookups of the same table by ID or foreign key when one batch query plus a map would do.
- Fetching full entities or populated relations when only a small field set is needed.
- Duplicate queries for existence checks, metadata, or related names inside the same request path.
- Broad `populate` usage that hydrates large graphs for a small derived value.
- Filtering, sorting, grouping, or deduplicating large datasets in Node when the database can do it earlier.
- Unbounded reads on hot paths, especially missing limits, pagination, or selective conditions.
- Runtime raw SQL strings or query-builder escapes that violate the repo constitution.
- Query patterns that scale linearly with rule count, device count, or event count on every request.

## Validate Findings

Only report issues you can support with code evidence.

For each finding:

1. Point to the exact file and line.
2. Name the query anti-pattern.
3. Explain the concrete scaling problem.
4. Describe the smallest safe fix that matches surrounding code.
5. Prefer fixes such as batch fetch plus map, narrower field selection, relation preloading, request-scope memoization, or moving filtering into SQL.

If you find no actionable problems, say so explicitly and mention what you did not measure, such as production query counts or missing benchmarks.

## Output Format

Produce a Markdown report with these sections for each finding:

- `Issue summary`
- `Severity` as `Low`, `Medium`, `High`, or `Critical`
- `Code location`
- `Query anti-pattern`
- `Why it gets expensive`
- `Suggested solution`
- `Example safer pattern`

Keep examples short and aligned with local TypeScript and MikroORM patterns.
