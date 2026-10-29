---
name: overview
description: >
  The web-ts stack (v3): one TypeScript app where server-rendered React pages, server functions, the Drizzle data
  layer and Better Auth run in the same process. Its shape, core technologies, house style, versions, how it
  hands off to a platform, and which skill of this plugin to load for which change. Use it at the start of any
  work in a project on web-ts, when choosing a stack for a new web app, or when asking "how is this app built?".
---

# Stack: web-ts

One TypeScript app: pages, server functions and auth live in the same process, and the browser talks only to that
app.

## Shape

```
browser ──► React pages (SSR, TanStack Router)
        └─► server functions ── validate input ──► service ──► db/ (Drizzle) ──► Postgres
                                                   └─► S3-compatible store (files)
auth: Better Auth, in-process, cookie sessions
```

- **Pages** render on the server and hydrate in the browser. Data comes through TanStack Query, with loaders that
  prefetch on the server.
- **Server functions** are the only API the browser calls. Each one validates its input with zod and calls a
  service. There is no separate REST layer, no controller class, no DI container.
- **Services** own the flow: authorization, transactions, queries, mapping rows to view models. Never imported by
  client code, which is what keeps the database driver out of the browser bundle.
- **The database** is reached only through Drizzle. The TypeScript schema is the source of truth; migrations are
  generated from it.
- **Auth** runs in the same process. A middleware puts the user in the server function's context.
- **Files** go to an S3-compatible bucket; a public bucket is served on its own domain.

Variant: **static**, the same stack prerendered to files, for a site with no server (a PWA, docs). No server
functions, no database.

## Core technologies

- TanStack Start (React 19, Vite, Nitro), TanStack Router and Query
- Drizzle ORM on Postgres
- Better Auth
- zod for every input

What a project adds for its own job (Tailwind and a component kit, TanStack Table, a search extension such as
ParadeDB, Vitest, Storybook, an email sender) belongs to the project, not to the stack.

## House style

- Prettier with tabs and semicolons, double quotes, trailing commas (es5), `arrowParens: "avoid"`, sorted
  imports.
- `@/` points at `src/`.
- TypeScript `strict`.
- One server function per file, named after it, with a zod validator.
- `api/ → service → db/` layering inside each domain folder.
- English in code, comments and docs; the UI in the product's language, from message files or the components.

## Versions

The plugin's major version is the stack version. A technology swap inside the same shape is a new major version;
a different language, runtime or shape is a new stack.

| Version | What changed | From |
|---|---|---|
| v1 | TanStack Start, with Supabase for database, auth and storage | 2026-03 (in production from 2026-04) |
| v2 | Drizzle ORM and server-first layering; Supabase kept only for auth and storage | 2026-08 |
| v3 | plain Postgres, Better Auth, an S3-compatible store (Garage) for files; no Supabase | 2026-10 |

This plugin describes **v3**. A project on v1 or v2 says so in its `CLAUDE.md`; the patterns still apply, except
where they name Better Auth or plain Postgres.

## Handing off to a platform

The stack says how the app is built; a platform says where it runs. The contract between them is small:

- **A container image** with a `/health` route that answers 200 only when the database is reachable.
- **No secrets at build time.** The image reads them when it starts, from a secret manager, and fails to start if
  it cannot.
- **Migrations before serving**: either applied on start by the single instance, or by hand before the release
  is merged. The project's `CLAUDE.md` says which.
- **One instance** when migrations run on start, or when the app keeps state in memory (a rate limiter).

## Which skill for which change

| Change | Skill |
|---|---|
| A new project on this stack | `stack-web-ts:scaffold` |
| A table, column, enum, index, relation or migration | `stack-web-ts:drizzle-schema` |
| A server function, a service, a query, middleware, errors | `stack-web-ts:server-functions` |
| A table of data in the UI: columns, filters, sorting, pagination, URL state | `stack-web-ts:data-tables` |
| A migration or an input that must not break the running release | `method:safe-changes` |
| Comments, prose, structure, review, PR | the other `method` skills |

## Before calling a change done

```bash
pnpm exec tsc --noEmit
pnpm test
pnpm build
```

`tsc` proves nothing about SQL, filters or what the browser shows. The pattern skills say how to check each.
