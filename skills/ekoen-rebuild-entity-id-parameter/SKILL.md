---
name: ekoen-rebuild-entity-id-parameter
description: Use when creating or refactoring ekoen-rebuild Next.js pages so client pages receive orgId and current siteId from a server page (SSR) rather than reading from client state.
---

# ekoen-rebuild: orgId/siteId pass-through

## When to use
- Any time you create or refactor a Next.js page under `packages/eKoEN` that renders client components needing `orgId` or `siteId`.
- Applies to smart-space-ac pages and any other ekoen-rebuild pages that fetch data client-side.

## Required pattern
1) **Server page** retrieves org/site from session using `getStrictSession` and passes them as props.
2) **Client page/component** receives `orgId` and `siteId` via props and uses them for React Query keys/fetchers.
3) **Do not** read org/site from Redux or other client state for these pages.

## Minimal example

Server page (SSR):

```tsx
import { getStrictSession } from '@app/_server-action/session/get-session';
import sessionKey from '@helpers/cookie/session-key';
import PageClient from './_components/page-client';

const Page = async () => {
  const org = await getStrictSession(sessionKey.ORG);
  const currentSite = await getStrictSession(sessionKey.CURRENT_SITE);
  return <PageClient orgId={org.id} siteId={currentSite.id} />;
};

export default Page;
```

Client page/component:

```tsx
'use client';

interface PageClientProps {
  orgId: string;
  siteId: string;
}

const PageClient = ({ orgId, siteId }: PageClientProps) => {
  // use orgId/siteId in React Query
  return <div />;
};

export default PageClient;
```

## Notes
- If query params include `siteId`, prefer that value but fallback to the SSR `siteId`.
- Keep IDs as primitive props; avoid passing full org/site objects to reduce serialization.
