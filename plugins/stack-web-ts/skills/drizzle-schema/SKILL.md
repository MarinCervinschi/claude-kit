---
name: drizzle-schema
description: >
  Conventions for the Drizzle data layer on the web-ts stack: adding or changing a table, column, enum, foreign
  key, relation, index or row type, and generating and applying migrations. Use it whenever work touches
  src/db/schema/, drizzle/, a database column or table, a migration, or a type derived from a table, and before
  writing raw SQL that has to survive a rebuild.
---

# Drizzle schema

The TypeScript schema is the source of truth. `drizzle-kit` diffs it and writes SQL; the database is never edited
directly. If you know EF Core Code First, it is the same model: `db:generate` is `migrations add`, `db:migrate` is
`database update`, a `--custom` migration is `migrationBuilder.Sql(...)`.

## Layout

```
src/db/
├── index.ts            getDb(): lazy pool, DATABASE_URL read after secrets load; Db, Tx, DbOrTx
└── schema/
    ├── index.ts        barrel: feeds `import * as schema` and db.query
    ├── entities/       one file per table, or per area when the tables are small and close
    └── relations.ts    relations only (one per Postgres schema when there are several)
```

`drizzle.config.ts` points at the schema **folder**, not the barrel, so a forgotten export can never drop a table
from a migration. The barrel still matters: it feeds `db.query` and relations.

Use `casing: "snake_case"` in both `drizzle.config.ts` and the `drizzle()` client. A camelCase key then maps to
its snake_case column without spelling the name; spell it only when the SQL name differs from the key.

## Naming

| Thing | Convention | Example |
|---|---|---|
| File | plural, kebab-case, mirrors the table (or the area) | `order-items.ts` |
| Table object | plural camelCase, mirrors the SQL name | `orderItems` |
| Relations | `<table>Relations` | `orderItemsRelations` |
| Enum | `<name>Enum` or the domain name | `statusEnum` |
| Row type | singular PascalCase, **derived** | `type Order = typeof orders.$inferSelect` |
| Insert type | `New<Row>`, derived | `type NewOrder = typeof orders.$inferInsert` |

Row types are never hand-written and never live in `src/db/`. They belong in `src/lib/<domain>/types.ts`, next to
the view models built on them.

## The one structural rule

**Relations files import entities. Entities never import relations.**

An entity file contains only what ends up in a migration: columns, indexes, constraints, foreign keys. Relations
produce no DDL; they exist only to feed `db.query`. Foreign keys resolve at module scope and their import graph
must stay a DAG (child imports parent); relations resolve lazily. Mixing the two creates import cycles that work
by accident and break with an error pointing at the wrong file. For the same reason, never reference another table
at module scope except inside `foreignKey({...})` or a `relations()` callback.

## Workflows

- Adding or changing a table, column, index or constraint: `references/entities.md`.
- Generating and applying a migration, and everything the DSL cannot express (triggers, functions, grants, seed
  rows, extension indexes): `references/migrations.md`.

## Non-negotiables

- **There is no `db:push`.** Always generate and migrate, so every change leaves a reviewable file. `push` also
  drops whatever it does not know, such as an index created in a custom migration.
- **Every migration is backward compatible.** A drop, rename, type change or new `NOT NULL` is split into expand
  and contract steps (the `method:safe-changes` skill).
- **Commit the TypeScript change, the generated `.sql` and the `drizzle/meta/` snapshot together.**
- **Never hand-edit a `.sql` file that has been applied anywhere shared.** Write a new migration.
- **How migrations are applied is written in `CLAUDE.md`**: on start by the single instance, or by hand before
  the release is merged. Never from a CI pipeline or a deploy hook as a third way.

## Verifying

`pnpm exec tsc --noEmit` is necessary and proves nothing about SQL. For anything beyond a trivial column, rebuild a
database from zero and diff it against the working one; the recipe is in `references/migrations.md`. It catches
inverted composite keys and indexes that silently lost their `DESC`.

A refactor that should be DDL-neutral (renaming exports, moving relations) must produce
`No schema changes, nothing to migrate` from `pnpm db:generate`. If it does not, something moved that should not
have.
