---
name: safe-changes
description: >
  How to change a database schema and an API without breaking the version that is still running: expand,
  migrate and contract; deprecating before dropping; the Postgres locks a migration can take; data backfills;
  versioning an endpoint; and the release order. Use it whenever you write or review a migration, change a
  column, constraint, index or enum, change an endpoint's input or behaviour, or plan what goes into a release.
---

# Safe changes

Two versions of an app always overlap. During a deploy the old process still serves requests while the new one
starts; a browser tab or a mobile client opened before the deploy keeps calling the old API; on staging a
migration may land before the code that uses it is merged. Every change therefore has to work with the code of
the release before it and the release after it.

The rule that follows: **every migration is backward compatible.** A change that is not gets split into steps
that each are, shipped in separate releases.

## Expand, migrate, contract

Any change that removes or reshapes something goes through three phases, each its own release:

1. **Expand.** Add the new structure next to the old. Nothing that exists changes.
2. **Migrate.** The code writes both, the data is copied over, then the code reads only the new one.
3. **Contract.** Remove the old structure, once no running version reads it.

A drop is always a contract step. It never ships in the release that stops using the column.

## The schema (Postgres)

| Change | How |
|---|---|
| Add a column | nullable, or with a constant default. Never `NOT NULL` without a default on an existing table |
| Drop a column | mark it obsolete (a deprecation note in the ORM, `COMMENT ON COLUMN` in SQL), stop using it, drop it in a later release |
| Rename a column | add the new one, write both and copy the data, read the new one, drop the old. Never `RENAME` |
| Change a type | a new column of the new type, then the same steps as a rename |
| `NOT NULL` on an existing column | backfill, `ADD CONSTRAINT … CHECK (col IS NOT NULL) NOT VALID`, `VALIDATE CONSTRAINT`, then `SET NOT NULL`, which uses the valid check instead of scanning |
| A new foreign key or check | `NOT VALID` first, `VALIDATE CONSTRAINT` in a second statement |
| An index on a table with data | `CREATE INDEX CONCURRENTLY`. It cannot run inside a transaction, so check how the migration runner wraps each file |
| An enum value | add only, never remove, and never use a value in the transaction that added it |
| Drop a table | as a column: unused for a release first |

**Locks.** Most `ALTER TABLE` forms take an `ACCESS EXCLUSIVE` lock, and every query on the table queues behind
it, including the ones that arrive after. Start each migration that alters a table the app writes to with
`SET lock_timeout = '5s';`, so a migration that cannot get its lock fails fast and is retried instead of stalling
the app.

**Backfills go in a job.** Filling existing rows goes in a script or job that works in batches, never inside a
migration. A migration that updates a large table holds its locks for the whole update.

## The API

Whatever carries it (REST, RPC, server functions, GraphQL), a client built for the previous release is still
calling.

- **An input only grows.** New fields are optional, with the old behaviour when they are absent. A field never
  becomes required and never changes meaning.
- **A changed behaviour is a new endpoint** or a new version of it. Move the clients to it, delete the old one in
  a later release.
- **An output only grows.** Old clients read the fields they know.
- **Moving or renaming an endpoint is a removal** for every client still on the old name. Do it in a release where
  that is acceptable, and say what those clients will see.

A stack may add its own rules here (how its endpoint ids are derived, how its generated clients are refreshed).
The stack's own skills say so.

## Releases

- **Order:** the expand migration, then the code, then the contract migration in a later release.
- **When migrations run** is a project decision, written in its `CLAUDE.md`: by hand before the release is
  merged, or on start by the app's single instance before it serves. Either way the migration lands before the
  code that needs it. Migrations on start need one instance only: two starting together would race.
- **Every release must run on the schema of the release after it.** Staging proves it when migrations land there
  first.
- **A feature flag** separates turning a behaviour on from deploying it, when the change is risky or needs data
  first.
- **Rolling back a deploy does not roll back the schema.** A release whose migrations are all expand steps can be
  rolled back by redeploying the previous image.

## Staging and branches

- If a migration already applied to staging changes afterwards, staging holds a version the file no longer
  describes. Rebuild staging from scratch instead of repairing it.
- Two branches must not both add a migration with the same number. Rebase and regenerate before merging.
- Never edit a migration that has been applied anywhere shared. Write a new one.

## Reviewing a migration

- [ ] Could the code of the previous release run on this schema?
- [ ] Is there a `DROP`, a `RENAME`, a type change or a new `NOT NULL`? Then it is a contract step: is the code
      that stopped using it already released?
- [ ] Does it alter a table the app writes to? Then it sets `lock_timeout`.
- [ ] Does it create an index on a table with data? Then `CONCURRENTLY`, outside a transaction.
- [ ] Does it update rows? Then the update belongs in a job.
- [ ] Does an endpoint's input become stricter, or its behaviour change under the same name? Then it is a new
      endpoint.
