# Migrations

```bash
pnpm db:generate --name add_something    # diff the schema -> drizzle/NNNN_add_something.sql
pnpm db:generate --custom --name grants  # an empty file for raw SQL
pnpm db:migrate                          # apply everything pending
pnpm db:check                            # migration history consistency
pnpm db:studio                           # browse the data
```

Extra flags pass through the pnpm script, so `pnpm db:generate --custom --name x` works.

`db:generate` diffs the TypeScript schema against the **snapshot** in `drizzle/meta/`, not against a live
database. A stale local database therefore never produces a spurious migration, and `pull` is the only way to
detect real drift.

## Applying

The project picks one way and writes it in `CLAUDE.md`:

- **On start.** The container runs a small script (`drizzle-orm/node-postgres/migrator`, one connection) before
  the server, and a failed migration stops the start. Needs a single instance.
- **By hand, before the release is merged**, environment by environment: staging as soon as the change needs it,
  production after a dump. A script that applies each file in its own transaction and prints the failing
  statement is clearer than `drizzle-kit migrate`, which runs them all in one.

In both cases CI applies every migration to an empty Postgres on each pull request, and applies nothing anywhere
else.

Consequences:

- Migration first, code second.
- Destructive changes are split into expand and contract steps across releases (`method:safe-changes`).
- Rolling back a deploy does **not** roll back the schema.

## What needs a custom migration

The DSL covers tables, columns, enums, indexes, constraints and foreign keys. Everything else is `--custom`:

- functions and triggers (an `updated_at` trigger per table that has the column)
- grants, revokes, default privileges, roles
- row-level security policies
- indexes from extensions (full-text, BM25, vector) the DSL cannot express
- reference data the app cannot start without
- removing an enum value, changing a generated column's expression, a type change that needs `USING`

Custom files are plain SQL. Separate statements with `--> statement-breakpoint` so drizzle-kit runs them one by
one:

```sql
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
--> statement-breakpoint

CREATE TRIGGER set_projects_updated_at BEFORE UPDATE ON public.projects
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
```

## Verifying against a rebuilt database

For anything beyond a trivial column, prove that the migrations rebuild the schema from zero.

1. Start an empty Postgres (a second compose service on another port) and apply every migration to it.
2. Dump both schemas with the same flags and diff them:

   ```bash
   pg_dump "$WORKING_URL" --schema-only --no-owner --no-privileges --no-comments > /tmp/working.sql
   pg_dump "$REBUILT_URL" --schema-only --no-owner --no-privileges --no-comments > /tmp/rebuilt.sql
   diff /tmp/working.sql /tmp/rebuilt.sql
   ```

3. The diff must be empty. Filter out only what is created at runtime (partitions a job queue adds, for example),
   and say what you filtered.

## Baselining an existing database

As of drizzle-kit 0.31 there is no `pull --init` and no `migrate --fake` for Postgres. To mark migrations as
applied on a database that already has the schema, insert the row into `drizzle.__drizzle_migrations` by hand
(the hash is the SHA-256 of the migration file), and only after a `pull` of that database diffs clean against the
TypeScript schema. One mismatched default and every later migrate tries to "fix" it.

On a local database, drop and rebuild instead of faking.

## Which database a command reaches

Verify the target from the result, never from the command you typed.

- `drizzle.config.ts` and the app may read different variables (an admin URL for migrations, a runtime URL for the
  app). Write down which reads which.
- A secret injector that wraps the `pnpm db:*` scripts can set variables **on top of** the shell environment, so an
  inline `DATABASE_URL=... pnpm db:migrate` may be silently replaced and the command reports success against
  another database. Run the tool directly (`pnpm exec drizzle-kit migrate`) when you need an inline URL to win.
