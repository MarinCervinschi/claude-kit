---
name: overview
description: >
  The dotnet-spa stack: one ASP.NET Core process that serves both the API and a Vite + React single-page app from
  the same origin, with the SPA built into the server's static files at publish time and unknown routes falling
  back to its index.html. Its shape, core technologies, how the pieces talk, and how to start a project with it.
  Use it for an internal tool, an admin console or a small product that should ship as one deployable, or when
  working in such a project.
---

# Stack: dotnet-spa

One .NET process, one origin: the API and the single-page app ship together.

## Shape

```
browser ──► https://app.example.com
              ├─ /api/*        ──► ASP.NET Core endpoints ──► data (EF Core or other)
              ├─ /assets/*     ──► hashed static files (the built SPA)
              └─ anything else ──► index.html (client-side routing takes over)
```

- **One deployable.** Publishing the server builds the SPA and copies its output into the server's static files
  (`wwwroot`). One image, one health check, one version number.
- **Same origin.** No CORS, and cookies work as they are: cookie auth with `SameSite=Lax` or `Strict`, with
  antiforgery on state-changing requests.
- **Routing split.** The API lives under one prefix (`/api`). The server maps static files first, then the API,
  then a fallback to `index.html` for every other path, so a deep link to a client route loads the app.
- **Development runs two processes**: the Vite dev server with hot reload, proxying `/api` to the ASP.NET Core
  process. Production runs one.

## Core technologies

- ASP.NET Core (minimal APIs), static files, `MapFallbackToFile("index.html")`
- Vite + React with TypeScript (a router and a data-fetching library such as TanStack Router and Query fit well)

The data layer, auth provider and UI kit are the project's choice.

## How the pieces talk

| From | To | How |
|---|---|---|
| Browser | SPA | the first request returns `index.html`; after that, client-side navigation |
| SPA | API | `fetch` to relative URLs (`/api/...`) with the auth cookie; typed through a generated client or shared types |
| API | data | in-process |
| Vite dev server | API | `server.proxy` for `/api` in `vite.config.ts` |

**Caching.** `index.html` is served with `Cache-Control: no-cache`, so a deploy is picked up on the next load. The
hashed assets get a long `max-age` with `immutable`.

**Unknown API routes** must return 404, not `index.html`: scope the fallback so it skips `/api`.

## How to start

```bash
dotnet new web -n App                          # the server
pnpm create vite App/ClientApp --template react-ts
```

- In `vite.config.ts`: `build.outDir` pointing at the server's `wwwroot` (or a folder the publish step copies),
  `emptyOutDir: true`, and `server.proxy: { "/api": "http://localhost:5000" }`.
- In `App.csproj`: a target before publish that runs the SPA's install and build, so `dotnet publish` produces the
  whole app. Keep the built files out of git.
- In `Program.cs`, in this order: `UseDefaultFiles()` and `UseStaticFiles()` (with the caching headers), the
  `/api` group, then `MapFallbackToFile("index.html")`.
- One multi-stage `Dockerfile`: a Node stage builds the SPA, a .NET SDK stage publishes, a runtime stage runs.

Layout and `CLAUDE.md`:

```
App/              the ASP.NET Core project, Program.cs, endpoints
App/ClientApp/    the Vite + React app
tests/
```

The `CLAUDE.md` names the two dev commands (the API and `vite`), the publish command, the `/api` prefix rule and the
auth model.

## Rules worth keeping

- The SPA never calls another origin for its own data. If it has to, that is a different stack.
- API errors are Problem Details with a message the SPA can show.
- One version: the SPA and the API are released together, so a changed endpoint and its caller ship in one image.
  Tabs left open across a deploy still run the old SPA: an endpoint's input only grows (`method:safe-changes`).

## Growing into a full stack

This is a base stack: one overview skill. When one of Marin's own projects uses it, the repeated parts become a
scaffold skill and pattern skills.
