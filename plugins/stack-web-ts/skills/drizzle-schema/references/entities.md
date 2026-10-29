# Entities

## Shape of an entity file

```ts
import { index, integer, pgTable, text, timestamp, unique, uuid } from "drizzle-orm/pg-core";

import { statusEnum } from "./enums";

export const projects = pgTable(
	"projects",
	{
		id: uuid().defaultRandom().primaryKey(),
		name: text().notNull(),
		code: text().notNull(),
		status: statusEnum().notNull().default("draft"),
		position: integer().default(0).notNull(),
		createdAt: timestamp({ withTimezone: true, mode: "string" }).defaultNow().notNull(),
	},
	table => [
		index("idx_projects_position").on(table.position),
		unique("projects_code_key").on(table.code),
	]
);
```

Tables in another Postgres schema use a handle: `export const catalog = pgSchema("catalog")`, then
`catalog.table(...)`.

Rules that matter:

- **Timestamps** pick one `mode` for the whole project and keep it. `"string"` surfaces ISO strings; switching to
  `"date"` later changes every consumer.
- **Constraint and index names are explicit** and match the database. Postgres autogenerates
  `<table>_<cols>_key` and `<table>_<col>_fkey`; keep those strings, or the next diff renames things.
- **Row-level security** only when the database is exposed through something that enforces it (a REST layer
  over Postgres, a shared role). An app that connects with its own role and checks access in services does not
  need it.

## Foreign keys

Use the explicit `foreignKey({...})` form in the third argument, not `.references()` inline, so the name is
pinned:

```ts
foreignKey({
	columns: [table.projectId],
	foreignColumns: [projects.id],
	name: "tasks_project_id_fkey",
}).onDelete("cascade"),
```

A composite primary key is `primaryKey({ columns: [...], name: "<table>_pkey" })`.

Foreign keys are the only place an entity may import another entity at module scope. That import graph must stay
a DAG: the child imports the parent, never the reverse.

## Enums

Declare enums once, in one schema (usually `public`), with `pgEnum`. Moving an enum to another schema handle moves
the type and breaks every column that uses it.

```ts
export const statusEnum = pgEnum("status", ["draft", "active", "archived"]);
```

Adding a value is a plain schema edit. **Removing one is not**: Postgres has no `DROP VALUE`. It needs a custom
migration that renames the type, creates the new one, casts every column and drops the old type.

## Generated columns

A `tsvector` or other generated column needs a custom type and its expression in the exact form Postgres
normalises it to (`'english'::regconfig`, `''::text`). A cosmetic difference reads as a change on every
`generate`.

```ts
fts: tsvector("fts").generatedAlwaysAs(
	sql`to_tsvector('english'::regconfig, COALESCE(name, ''::text))`
),
```

A generated column cannot be altered in place: a new expression means dropping and recreating the column and its
indexes, in a custom migration. Never return it to the client; select columns explicitly.

## Indexes: two traps

**`.desc()` is silently dropped when combined with `.op()`.** Write descending indexes without the opclass:

```ts
index("idx_events_created_at").using("btree", table.createdAt.desc().nullsFirst()),
```

**Introspection output is not trustworthy.** `drizzle-kit pull` has been seen emitting the columns of a composite
unique in the wrong order and opclasses shifted by one column. Check anything copied from it against the
database:

```sql
select indexdef from pg_indexes where indexname = '<name>';
```

## Check constraints

```ts
check("tasks_estimate_check", sql`estimate >= 0`),
```

Copy the expression from `pg_get_constraintdef()`, not from the original SQL: Postgres stores a normalised form,
and any difference shows up as a diff forever.

## Relations

In `relations.ts`, never in the entity file:

```ts
export const projectsRelations = relations(projects, ({ many }) => ({
	tasks: many(tasks),
}));
```

A relation belongs to the file of the table that **owns** it (the first argument).

Two relations between the same pair of tables need a `relationName` on **both** sides:

```ts
author:   one(users, { fields: [tasks.authorId],   references: [users.id], relationName: "taskAuthor" }),
assignee: one(users, { fields: [tasks.assigneeId], references: [users.id], relationName: "taskAssignee" }),
```

Relations are ORM-only. Adding, changing or removing one must produce `No schema changes` from `db:generate`.

## Row types

Derived, in `src/lib/<domain>/types.ts`:

```ts
import type { projects } from "@/db/schema";

export type Project = typeof projects.$inferSelect;
export type NewProject = typeof projects.$inferInsert;
export type ProjectCard = Project & { openTasks: number };
```

## Checklist for a new table

1. Create the entity with columns, indexes, constraints and foreign keys.
2. Add its relations to `relations.ts`, if `db.query` will use them.
3. Export both from `src/db/schema/index.ts`.
4. `pnpm db:generate --name add_<table>` and read the SQL before applying it.
5. Add an `updated_at` trigger in a custom migration if the table has that column.
6. Derive the row types where they are consumed.
