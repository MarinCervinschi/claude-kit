# claude-kit

How I build software with Claude Code, packaged as a plugin marketplace. One plugin holds the method, which fits
any repo. One plugin per named stack holds how I build with that stack. A project switches on the method and the
stack it uses, and every repo then reads the same version of each skill instead of a copy that drifts.

## Plugins

| Plugin | Level | Skills |
|---|---|---|
| `method` | | `grill-me`, `spec-interview`, `task-tracking`, `plain-writing`, `code-comments`, `design-principles`, `docs`, `feature-review`, `safe-changes`, `pre-pr-checklist` |
| `stack-web-ts` (v3) | full | `overview`, `scaffold`, `drizzle-schema`, `server-functions`, `data-tables` |
| `stack-rust-py-lab` | base | `overview` |
| `stack-dotnet-next` | base | `overview` |
| `stack-dotnet-spa` | base | `overview` |
| `stack-dotnet-blazor` | base | `overview` |

Skills are namespaced by plugin, so they are invoked as `method:plain-writing` or `stack-web-ts:overview`.

### Stacks

A stack is a shape: the pieces, how they talk, and the few core technologies that make the shape what it is. It
is not a dependency list; the libraries a project needs for its own job belong to the project.

- Names are descriptive, `<shape>-<key technology>`, and the plugin is `stack-<name>`.
- The plugin's major version is the stack's version. Swapping a technology inside the same shape is a new major
  version; a different language, runtime or shape is a new stack.
- A **base** stack is one overview skill: the shape, the core technologies, how the pieces talk, how to start. It
  becomes **full** when a project of mine uses it, and gains a scaffold skill and the pattern skills that repeat.
- Each project's `CLAUDE.md` says which stack and version it uses.

A stack says how an app is built, not where it runs. Deployment lives in a separate, private plugin.

## Install

In the project's folder:

```bash
claude plugin marketplace add MarinCervinschi/claude-kit --scope project
claude plugin install method@claude-kit --scope project
claude plugin install stack-web-ts@claude-kit --scope project
```

`--scope project` records the marketplace and the enabled plugins in the committed `.claude/settings.json`. On
another machine, Claude Code registers the marketplace after the workspace trust prompt, but each machine still
installs each plugin once: enabling a plugin in settings does not install it.

To try a plugin from a local checkout without installing it:

```bash
claude --plugin-dir ./plugins/method
```

## What belongs here

This marketplace is public on purpose: my public repos enable it in their committed settings, so whoever
contributes gets the same skills their `CLAUDE.md` routes to. A skill belongs here when it helps someone working in
one of those repos, or adopting the method or a stack, without my servers or accounts.

What names my servers, accounts or secret-manager layout, or only makes sense on my machines (the deploy runbooks
first), lives in a private marketplace of mine. A repo enables a private plugin with `--scope local`, never in its
committed settings, because a contributor could not install it. My personal preferences (language, how I want to
be asked questions) live in my user-level `CLAUDE.md`, not in a skill.

## Credits

- `grill-me` adapts Matt Pocock's `grill-me` and `grilling` skills
  ([mattpocock/skills](https://github.com/mattpocock/skills), MIT): the design tree, the rounds over the frontier
  and the split between facts and decisions. The sizing step, the assumptions list and where decisions are
  written are mine. `spec-interview` runs its interview the same way and adds the `SPEC.md` output.
- `feature-review` works best with three third-party plugins, used when installed: `taste-skill`,
  `ui-ux-pro-max` and `interfaces`.

## Before every push

```bash
scripts/check-public.sh
```

It scans every file a commit would carry for secrets, tokens, private keys, IP addresses, tailnet names, machine
paths, email addresses and em dashes. It also checks a private list of names (my hosts and domains, and products,
clients and people covered by an NDA). That list cannot live in this repo, because a committed list would publish
the names it protects. The scan reads it from `$CLAUDE_KIT_DENYLIST`, which each of my machines points at a copy
kept in a private repo, or else from the gitignored `scripts/denylist.local`. Without a list the scan stops with
exit code 2; `scripts/denylist.example` shows the format.

To run it on every push:

```bash
ln -s ../../scripts/check-public.sh .git/hooks/pre-push
```

### In my other public repos

The same scan guards my public app repos, on every file a push carries.

- A copy of the script at `scripts/check-public.sh`, identical to this one.
- `.githooks/pre-push` with `exec scripts/check-public.sh`, enabled once per clone with
  `git config core.hooksPath .githooks`.
- An optional `.check-public` file at the top of the repo, one directive per line:
  - `ignore <glob>` for lockfiles and generated data;
  - `allow-name <regex>` for a deny-list name the repo publishes on purpose (its own domain);
  - `allow <regex> [in <glob>]` for a match the repo publishes on purpose, of any check, optionally in one path
    (its contact address, a word in one file that collides with a deny-list name);
  - `warn <label>` to report a check without failing the push (`warn em dash`).

A repo whose tree still holds findings starts with `--pushed`, which scans only the lines the pushed commits add.
Once the whole-tree scan is clean, the hook drops `--pushed`, as it has in my public repos since 2026-11-01.

## Validate

```bash
claude plugin validate .
claude plugin validate plugins/method
```

## License

MIT, see [LICENSE](LICENSE).
