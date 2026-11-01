---
name: scaffold
description: >
  Starts a new project on the web-ts stack (v3): TanStack Start, Drizzle on Postgres, Better Auth, the house style,
  the folder layout, the error and auth middleware, a health route, a container that reads secrets and migrates on
  start, and the first CLAUDE.md. Use it when the user wants a new web app on web-ts, says "scaffold", "new app",
  "set up the project", or has a fresh SPEC.md and is ready for the first commit of code.
---

# Scaffold a web-ts app

The goal of the first session: an app that builds, starts in a container, answers `/health`, signs a user in, and
has the layout every later feature drops into. No feature code yet.

Start from the decisions in `SPEC.md` (the `method:spec-interview` skill writes it). If there is none, ask
whether to run the interview first.

## 1. Create the app

- Create it with the TanStack Start CLI, using `pnpm`. The command changes between releases: check the current
  one in the TanStack Start docs before running it.
- Pin the package manager in `package.json` (`"packageManager": "pnpm@<version>"`).
- Add: `drizzle-orm`, `pg`, `better-auth`, `zod`, `@tanstack/react-query` with the router's SSR query
  integration; as dev dependencies `drizzle-kit`, `@types/pg`, `vitest`, `prettier` with the import-sort and
  Tailwind plugins, `dotenv-cli`.
- `tsconfig.json`: `strict`, and `paths: { "@/*": ["./src/*"] }`.

## 2. House style

`.prettierrc.json`:

```json
{
	"useTabs": true,
	"semi": true,
	"singleQuote": false,
	"trailingComma": "es5",
	"arrowParens": "avoid",
	"printWidth": 88,
	"importOrder": ["^(react/(.*)$)|^(react$)", "<THIRD_PARTY_MODULES>", "^@/(.*)$", "^[./]"],
	"importOrderSeparation": true,
	"importOrderSortSpecifiers": true,
	"plugins": ["@trivago/prettier-plugin-sort-imports", "prettier-plugin-tailwindcss"]
}
```

## 3. Layout

```
src/
  routes/                 file routes; __root.tsx; api/auth/$.ts; health.ts
  components/             shared components; ui/ for the primitives
  lib/
    <domain>/
      api/<endpoint>.ts   one server function per file
      service.ts          the flow
      db/<table>.ts       only for queries shared across modules
      schemas.ts          zod inputs
      types.ts            row types and view models
      queries.ts          client: queryOptions
      mutations.ts        client: useMutation hooks
    auth/server.ts        Better Auth instance; auth/client.ts for the browser
    server/errors.ts      AppError and its subclasses
    server/middleware/    errors.ts, auth.ts
  db/
    index.ts              getDb(), Db, Tx, DbOrTx
    schema/               entities, relations, index.ts barrel
  router.tsx              router + QueryClient + SSR query integration
  start.ts                global function middleware
drizzle/                  generated migrations and meta/
scripts/migrate.mjs       applies migrations, plain JS
compose.yaml              local Postgres
Dockerfile, docker-entrypoint.sh
CLAUDE.md, SPEC.md, README.md
.gitignore                with CLAUDE.local.md, which a *.local pattern does not match
.worktreeinclude          CLAUDE.local.md, so Claude Code copies it into the worktrees it creates
```

The `server-functions` skill explains the `lib/<domain>` layers; the `drizzle-schema` skill explains `db/`.

## 4. The database

`compose.yaml` runs the same Postgres image as production, bound to loopback only:

```yaml
services:
  db:
    image: postgres:17
    environment:
      POSTGRES_USER: app
      POSTGRES_PASSWORD: app
      POSTGRES_DB: app
    ports:
      - "127.0.0.1:54330:5432"
    volumes:
      - db-data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD", "pg_isready", "-U", "app"]
      interval: 1s
      retries: 30
volumes:
  db-data:
```

`drizzle.config.ts` points at the schema **folder**, uses `casing: "snake_case"`, and refuses to run without a URL:

```ts
import { defineConfig } from "drizzle-kit";

const url = process.env.DATABASE_URL;
if (!url) throw new Error("DATABASE_URL is not set. Run drizzle-kit through the pnpm db:* scripts.");

export default defineConfig({
	dialect: "postgresql",
	schema: "./src/db/schema",
	out: "./drizzle",
	dbCredentials: { url },
	casing: "snake_case",
	strict: true,
});
```

`src/db/index.ts` opens the pool lazily, so the URL is read after the secrets are loaded:

```ts
import { drizzle } from "drizzle-orm/node-postgres";
import { Pool } from "pg";

import * as schema from "./schema";

export type Db = ReturnType<typeof createDb>;
export type Tx = Parameters<Parameters<Db["transaction"]>[0]>[0];
export type DbOrTx = Db | Tx;

let db: Db | null = null;

function createDb(pool: Pool) {
	return drizzle(pool, { schema, casing: "snake_case" });
}

export function getDb(): Db {
	if (db) return db;
	const connectionString = process.env.DATABASE_URL;
	if (!connectionString) throw new Error("DATABASE_URL is not set");
	db = createDb(new Pool({ connectionString, max: 10 }));
	return db;
}
```

Scripts: `db:up` (`docker compose up -d --wait db`), `db:down`, `db:generate`, `db:migrate`, `db:studio`, each
through `dotenv run` for local work. There is no `db:push`.

## 5. Errors, middleware, auth

- `src/lib/server/errors.ts`: an `AppError` with a code (`UNAUTHORIZED`, `FORBIDDEN`, `NOT_FOUND`, `CONFLICT`,
  `INVALID`, `UNAVAILABLE`) and one subclass each. Its message is written for the user. Add
  `rethrowUniqueViolation(err, message)`, which turns Postgres error `23505` into a `Conflict`.
- `src/lib/server/middleware/errors.ts`: a function middleware that lets redirects, not-found and `AppError` pass,
  logs anything else and replaces it with a generic message. Register it globally in `src/start.ts`:

  ```ts
  export const startInstance = createStart(() => ({
  	functionMiddleware: [errorMiddleware],
  }));
  ```

- `src/lib/auth/server.ts`: the Better Auth instance, created lazily like the database, with the Drizzle adapter,
  the TanStack Start cookie plugin, and the providers the spec chose. Its tables live in the schema like any
  other. Mount the handler at `src/routes/api/auth/$.ts` for `GET` and `POST`.
- `src/lib/server/middleware/auth.ts`: `authMiddleware` requires a session and puts `context.user` in scope;
  `optionalAuthMiddleware` puts the user or `null`. Role checks get their own middleware when there are roles.

## 6. Health

```ts
export const Route = createFileRoute("/health")({
	server: {
		handlers: {
			GET: async () => {
				try {
					await getDb().execute(sql`select 1`);
					return new Response("ok", { headers: { "cache-control": "no-store" } });
				} catch {
					return new Response("database unreachable", {
						status: 503,
						headers: { "cache-control": "no-store" },
					});
				}
			},
		},
	},
});
```

No details in the body: the route is public.

## 7. The container

`scripts/migrate.mjs` applies `drizzle/` with `drizzle-orm/node-postgres/migrator` on a pool of one connection,
then exits. Plain JavaScript, so the runtime image needs no TypeScript tooling.

`Dockerfile`, multi-stage:

1. `deps`: `pnpm install --frozen-lockfile` with a cache mount.
2. `build`: `pnpm build`. **No secrets**: the app reads them at start.
3. `prod-deps`: `pnpm install --prod --ignore-scripts`, only for what `migrate.mjs` imports (`drizzle-orm`, `pg`);
   the server itself is bundled in `.output/`.
4. `runtime`: the secret manager's CLI, `.output/`, `drizzle/`, `scripts/migrate.mjs`, the entrypoint, a non-root
   user, `EXPOSE 3000`.

`docker-entrypoint.sh` fails fast if its login variables are missing, logs into the secret manager, then runs the
migrations and the server inside the secret manager's environment:

```sh
#!/bin/sh
set -eu
# check the login variables, exchange them for a short-lived token, then:
exec <secret-manager> run --token="$token" ... -- sh -c 'node scripts/migrate.mjs && exec "$@"' sh "$@"
```

A failed migration stops the start, so a deploy never serves code ahead of its schema. If the project applies
migrations by hand instead, drop the `migrate.mjs` step and say so in `CLAUDE.md`.

## 8. Tests

Vitest. Unit tests next to the code they test; integration tests against a throwaway Postgres (a second compose
service on another port, migrated from zero). A write flow is tested inside a transaction that is rolled back.

## 9. CLAUDE.md

A router, not an essay, written for anyone who clones the repo:

- one line on what the app is, and a dated status line;
- the stack: `web-ts v3` and what the project adds;
- a commands table (dev, local db, generate and migrate, test, typecheck, build), each one working without the
  owner's secrets or saying what it needs;
- the architecture, one line per folder or important file;
- the non-negotiable rules ("never `drizzle-kit push`", "one instance", how migrations are applied);
- skill routing: which skill for which kind of change (the table in `stack-web-ts:overview`, plus the project's
  own skills), from plugins a contributor can install.

What only the owner needs stays out of it: where the app runs, the deploy, server names and addresses, the secret
manager's layout, the commands that reach staging and production, and private plugins. That goes in notes kept
outside the repo (with the deploy, in a private repo), imported by a `CLAUDE.local.md` that git ignores; a private
plugin is enabled with `--scope local`, never in the committed `.claude/settings.json`.

## 10. Check it

```bash
pnpm db:up && pnpm db:generate --name init && pnpm db:migrate
pnpm exec tsc --noEmit
pnpm test
pnpm build
docker build -t app-check .
```

Then run the image against the local database with the secrets passed in, open `/health`, and sign in once. Report
what ran and what did not; nothing is committed until the user asks.
