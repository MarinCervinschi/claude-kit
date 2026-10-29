---
name: server-functions
description: >
  How server functions are structured on the web-ts stack: api/ endpoints, the service flow, when a query earns a
  db/ file, middleware, errors, input validation, view models, and how a change to a server function stays safe
  for tabs opened before a deploy. Use it whenever you add, move, split or review a createServerFn, a Drizzle
  query behind one, or a domain's api/service/db layout.
---

# Server functions

`createServerFn` is the only API the browser talks to. There is no controller class, no DI container and no
repository interface: **a module is the class, its exported functions are its public members and the
non-exported ones are its private methods.**

```
src/lib/<domain>/
  api/<endpoint>.ts     one server function per file, named after it
  api/index.ts          re-exports only
  service.ts            the flow: rules, transactions, queries, view models
  service/<area>.ts     the same, split by area when one file gets long
  db/<table>.ts         only for queries used from more than one module
  schemas.ts            zod input schemas
  types.ts              row types from $inferSelect, and view models
  columns.ts            shared column maps, when two queries must return one shape
  queries.ts            client: TanStack Query queryOptions
  mutations.ts          client: useMutation hooks
```

## The layers

### api/: the endpoint

One file per server function, named after it in kebab-case without the `Fn`: `startSessionFn` lives in
`api/start-session.ts`. Grep works in both directions and the file is findable without a search.

It declares middleware, validates input and calls a use case. Nothing else.

```ts
export const startSessionFn = createServerFn({ method: "POST" })
	.middleware([authMiddleware])
	.inputValidator(startSessionSchema)
	.handler(({ data, context }) => startSession(context.user.id, data));
```

The validator method has been renamed between TanStack Start releases (`validator`, `inputValidator`). Use the
one the installed types expose, and the same one everywhere.

An endpoint that is a single query with no rules may hold that query in its handler. Export nothing else from an
`api/` file: a live export keeps server-only code reachable from the client graph.

### service: the flow

Owns transactions, authorization calls, its own queries and the mapping to view models. One `service.ts` per
domain; split into `service/<area>.ts` when it grows.

Never imported by client code. That is what keeps `pg` out of the browser bundle: the compiler strips the
handler and every import only the handler used.

### db/<table>.ts: the exception

**A query earns a file here only when it is used from more than one module.** With one caller it is a private
function in that service.

- **Cohesion beats the counting rule.** Once a table has a `db/` file, all of its queries go there. Splitting one
  table between a service and a `db/` file is worse than either choice.
- **The first argument is always `db: DbOrTx`.** The same query then runs standalone or inside
  `db.transaction()`, and a test can drive a whole write flow in a transaction and roll it back.

No authorization, no user and no view models in `db/`.

## Why not a repository layer

Coming from EF Core, the reflex is to inject a `DbContext` and to hide queries behind an interface. Neither
transfers:

- **Drizzle is not a `DbContext`.** No change tracking, no unit of work, no `SaveChanges()`. A query is a function
  of (connection, arguments), so passing the handle explicitly *is* the injection.
- **An interface over the ORM buys nothing here.** In .NET it exists largely to mock the context; here the write
  paths are tested against real Postgres in a rolled-back transaction.
- **A class pays for itself** only with request-scoped state or a second implementation.

## Middleware

In `src/lib/server/middleware/`:

| Middleware | What it does |
|---|---|
| `authMiddleware` | requires a session, puts `context.user` in scope |
| `optionalAuthMiddleware` | `context.user` or `null`, for pages anonymous visitors can see |
| `errorMiddleware` | logs the real error, lets `AppError`, redirects and not-found through, replaces anything else |
| a role middleware | loads the role, so `context.user` carries it |

`errorMiddleware` is registered globally in `src/start.ts` (`createStart(() => ({ functionMiddleware: [...] }))`).
An endpoint declares only what it adds.

**Never wrap `createServerFn` in a factory.** The Vite plugin finds it by import binding; a wrapper like
`authedFn({...})` compiles and then silently fails to register the function.

## Errors

`src/lib/server/errors.ts` holds `AppError` and its subclasses (`Unauthorized`, `Forbidden`, `NotFound`,
`Conflict`, `Invalid`, `Unavailable`). Its message is written for the user and reaches the toast verbatim.
Anything else that escapes a handler is logged with its stack and replaced by a generic message, so a database
error never reaches the browser. **A message the user should read must be an `AppError`**; a plain
`throw new Error("…")` is masked.

`rethrowUniqueViolation(err, "…")` turns Postgres error `23505` into a `Conflict` with a message worth reading,
and rethrows everything else untouched.

## Input and output

- Validate with a zod schema from `schemas.ts`, never a passthrough `(input: T) => input`.
- View models are camelCase and derive from `$inferSelect`.
- Never send a generated column (a `tsvector`) to the client: select columns explicitly (`columns.ts`).
- On read endpoints whose route renders a not-found state, return `null` for "not found or not visible"; throw
  for real failures.

## Two SQL traps the compiler cannot see

- **Aliased subqueries need an explicit alias per column.** Two joined tables with a `code` column both render as
  `"alias"."code"` otherwise.
- **A `sql` template renders column references unqualified.** `sql\`… where ${a.classId} = ${b.classId}\``
  becomes `where "class_id" = "class_id"`: ambiguous at best, silently wrong at worst. Build correlated subqueries
  with the query builder (`exists(db.select()…)`), which qualifies them, and wrap the result in
  `sql<boolean>\`${…}\`` if you need to name its type.

## Changing a server function safely

A server function's id is derived from its file and export name, and the client module a browser already loaded
has that id baked in. A tab opened before a deploy keeps calling the old id with the input shape it knew.

- **An input only grows.** New fields are optional, with the old behaviour when absent. A field never becomes
  required and never changes meaning.
- **A changed behaviour is a new function.** Write `startSessionV2Fn` next to `startSessionFn`, move the client to
  it, delete the old one in a later release.
- **An output only grows.**
- **Moving or renaming a server function is a removal** for every open tab. Do it in a release where a reload is
  acceptable.

After moving or renaming one in development, **hard-reload the browser**. A stale tab fails in one of two ways
that look like application bugs:

| What happened to the file | What the dev server logs |
|---|---|
| deleted or moved | `Invalid server function ID: <base64>` |
| still there, export gone | `Cannot read properties of undefined (reading 'method')` |

Decode the base64 in the request URL to see which file and export the tab is asking for. The same happens in
production to tabs left open across a deploy.

The general rules for migrations and releases are in `method:safe-changes`.

## Before calling it done

```bash
pnpm exec tsc --noEmit     # catches every consumer of a renamed field
pnpm test                  # including write flows in a rolled-back transaction
pnpm build                 # the client output must contain no drizzle or pg
```

A new read path also gets a smoke check against a real database if the project keeps one; `tsc` proves nothing
about SQL.
