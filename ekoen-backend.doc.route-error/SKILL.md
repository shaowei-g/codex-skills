---
name: ekoen-backend.doc.route-error
description: Add HttpErrorRes responses to eKoEN backend routes when controllers can throw errors from app/util/errors/index.ts
---

# Target repo :ekoen-backend, Route Error Documentation

Use this skill when adding or updating error responses in TSOA controllers under `app/rpc/v2/controller/**`.

## Goal

If a controller method can throw a defined error from `app/util/errors/index.ts`, document it with TSOA `@Response` using `HttpErrorRes` (or `HttpErrorRes[]` for multiple errors).

## Quick Flow

1. Identify the controller method(s) that can throw errors (directly or via use case/service).
2. Locate the matching error definitions in `app/util/errors/index.ts` (namespace in `ekErr`).
3. Import `HttpErrorRes` and `ekErr` into the controller file.
4. Add `@Response` decorators above the route method:
   - Single error: `@Response<HttpErrorRes>('422', error.message, error)`
   - Multiple errors: `@Response<HttpErrorRes[]>('409', 'failed, one of list', [errorA, errorB])`
5. Use `toHttpResBody()` to supply the error examples, consistent with existing controllers.

## Controller Example Pattern

```ts
import { Response } from 'tsoa';
import { ekErr, type HttpErrorRes } from 'app/util';

const exampleA = new ekErr.EkoEN.SomeError().toHttpResBody();
const exampleB = new ekErr.Api.InvalidArgs().toHttpResBody();

@Response<HttpErrorRes>('422', exampleB.message, exampleB)
@Response<HttpErrorRes[]>('409', 'failed, one of list', [exampleA])
```

## Notes

- Keep error documentation in the controller (presentation layer).
- Do not add new error definitions here—only reference existing ones.
- Prefer consistent HTTP codes defined in `makeError`.
