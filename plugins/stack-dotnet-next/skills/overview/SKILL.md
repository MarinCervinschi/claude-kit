---
name: overview
description: >
  The dotnet-next stack: an ASP.NET Core API that publishes REST and an OpenAPI document, a separate Next.js front
  that calls it through a client generated from that document, EF Core on Postgres, and long-running work in
  separate workers outside the request. Its shape, core technologies, how the pieces talk, and how to start a
  project with it. Use it when choosing a stack for a product with a .NET backend and a React front, or when
  working in such a project.
---

# Stack: dotnet-next

A .NET API and a separate Next.js front, joined by a contract: the OpenAPI document.

## Shape

```
browser ──► Next.js (server and client components)
              └─► generated client ──HTTP──► ASP.NET Core API ──► EF Core ──► Postgres
                                                  └─► enqueue ──► worker(s): exports, imports, AI calls, emails
```

- **The API owns the domain and the data.** It publishes REST endpoints and an OpenAPI document generated from
  the code.
- **The front never hand-writes a request.** A client generated from the OpenAPI document gives typed calls end
  to end. When the API changes, the client is regenerated in the same change, and CI fails if the committed
  client is stale.
- **Long-running work leaves the request.** The API records the job and returns; a worker process picks it up,
  retries it and reports progress. A durable workflow engine fits when a job has several steps that must survive
  a restart; a queue fits when each job is one step.
- **The database belongs to the API.** The front and the workers never open their own connection to the API's
  tables; workers share the data project and its migrations.

## Core technologies

- ASP.NET Core (minimal APIs or controllers), the built-in OpenAPI generation
- EF Core with Npgsql on Postgres, migrations in code
- Next.js (App Router) with a client generated from the OpenAPI document (`openapi-typescript` with a small fetch
  wrapper, or a full generator such as Orval or Kiota)

The workflow engine or queue, auth provider, logging sink and observability are the project's choice.

## How the pieces talk

| From | To | How |
|---|---|---|
| Browser | Next.js | pages and server actions |
| Next.js | API | HTTP through the generated client, from server components or the browser |
| API | Postgres | EF Core, one `DbContext` per request |
| API | worker | a durable job (workflow start or queue message), never an in-process background task for real work |
| Worker | Postgres | the same data project and `DbContext` |

**Auth.** Pick one model and write it in `CLAUDE.md`: the API issues and checks the session (cookie on a shared
parent domain, or a token the Next.js server forwards), and the front only carries it. The API is the one that
says no.

**Errors.** The API answers with Problem Details (`application/problem+json`); the generated client surfaces them
as typed errors, and the front maps them to messages written for the user.

## How to start

```bash
dotnet new sln -n App
dotnet new webapi -n App.Api            # OpenAPI on by default in recent templates
dotnet new classlib -n App.Data         # DbContext, entities, configurations, migrations
dotnet new worker -n App.Worker         # long-running jobs
dotnet add App.Data package Npgsql.EntityFrameworkCore.PostgreSQL
dotnet tool install --global dotnet-ef
dotnet ef migrations add Init -p App.Data -s App.Api

npx create-next-app@latest web --ts --app
```

- One `Directory.Build.props` with nullable on and warnings as errors.
- A script that exports the OpenAPI document from the built API and regenerates the client into `web/`; CI runs it
  and fails on a diff.
- Local Postgres in `compose.yaml`; the API applies migrations on start in development only, or a migration bundle
  runs before the deploy.

Layout and `CLAUDE.md`:

```
api/   App.Api, App.Data, App.Worker, tests     dotnet build, dotnet test
web/   Next.js app, generated client             pnpm typecheck, pnpm build
```

The `CLAUDE.md` says how the client is regenerated, how migrations are applied, which jobs run in workers, and the
auth model.

## Rules worth keeping

- Every endpoint is in the OpenAPI document, with its errors. An endpoint the client cannot see does not exist.
- An endpoint's input only grows; a changed behaviour is a new endpoint or a new version (`method:safe-changes`).
- Nothing that can take more than a couple of seconds runs inside a request.
- Configuration and secrets come from the environment at start, never from a committed file.

## Growing into a full stack

This is a base stack: one overview skill. When a project uses it, the repeated parts become a
scaffold skill and pattern skills (EF Core configurations, the client regeneration, the job pattern).
