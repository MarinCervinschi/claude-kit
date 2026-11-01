---
name: overview
description: >
  The dotnet-blazor stack: Blazor Server, where UI components run on the server, the browser keeps a live SignalR
  connection and receives UI updates, and components call services and EF Core in-process, so the UI needs no
  public API. Its shape, core technologies, how the pieces talk, the costs of per-connection state, and how to
  start a project with it. Use it for a data-heavy internal or back-office app in .NET, or when working in such a
  project.
---

# Stack: dotnet-blazor

A full .NET app whose UI runs on the server: no public API, no client-side state store.

## Shape

```
browser ◄──SignalR circuit──► server: Razor components ──► services ──► EF Core ──► Postgres / SQL Server
                                        (state per circuit)
```

- **Components run on the server.** The browser renders a DOM that the server patches over a WebSocket. Clicks and
  input travel to the server as events.
- **Services in-process.** A component injects a service and calls it directly. There is no HTTP layer between UI
  and logic, so there is no public API to secure or version for the UI.
- **State lives on the server, per connection** (a circuit). Scoped services are scoped to the circuit, not to a
  request.

## Core technologies

- ASP.NET Core with Blazor (the Blazor Web App template with Interactive Server render mode)
- EF Core
- A component library (MudBlazor or similar) for tables, forms and dialogs

The database, auth provider and anything else the domain needs belong to the project.

## How the pieces talk

| From | To | How |
|---|---|---|
| Browser | server | the first request renders HTML; then a SignalR circuit carries events and UI diffs |
| Component | service | constructor or `[Inject]` injection, a direct call |
| Service | database | EF Core through `IDbContextFactory`, one short-lived context per operation |
| Server | browser (push) | update a component's state and call `StateHasChanged`, from any server-side event |

**Why a context factory.** A circuit lives for minutes or hours, and a scoped `DbContext` would live as long,
tracking every entity it ever loaded and failing on concurrent use. Create a context per operation
(`await using var db = await factory.CreateDbContextAsync()`).

## Costs to plan for

- **Memory per connection.** Every open tab holds a circuit and its state on the server. Keep component state
  small and dispose what you subscribe to.
- **Latency on every interaction.** Each event is a round trip. Fine on a LAN or the same region; noticeable far
  away. Debounce text input that triggers work.
- **Reconnection.** A dropped connection shows the reconnect UI; a server restart loses circuit state. Keep
  anything the user cannot lose in the database or the URL.
- **Scaling out** needs sticky sessions (or a SignalR backplane service), because a circuit lives on one server.

## How to start

```bash
dotnet new blazor -n App --interactivity Server
dotnet add App package Npgsql.EntityFrameworkCore.PostgreSQL   # or the provider you use
dotnet add App package MudBlazor                                 # or another component library
```

- Register `AddDbContextFactory<AppDbContext>(...)`, not `AddDbContext`, for anything components touch.
- Set the render mode once (globally on the router, or per page) and write it in `CLAUDE.md`.
- Authentication with cookie auth and `AuthorizeView` / `[Authorize]` on pages; the circuit carries the user.
- Nullable on and warnings as errors in `Directory.Build.props`.

Layout and `CLAUDE.md`:

```
App/Components/   pages and components, by feature
App/Services/     the logic components call
App/Data/         DbContext, entities, configurations, migrations
tests/
```

The `CLAUDE.md` names the render mode, the context-factory rule, how migrations are applied, and the deploy
constraints (sticky sessions, one region).

## Rules worth keeping

- Components render and route events to services; the rules live in services, so they can be tested without a
  browser.
- No `DbContext` injected into a component.
- Long work (an import, a report) runs outside the circuit, in a hosted service or a worker, and reports progress
  back; the circuit only shows it.

## Growing into a full stack

This is a base stack: one overview skill. When a project uses it, the repeated parts become a
scaffold skill and pattern skills.
