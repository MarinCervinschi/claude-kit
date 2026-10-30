# claude-kit

How I build software with Claude Code, packaged as a plugin marketplace. One plugin holds the method, which fits
any repo. One plugin per named stack holds how I build with that stack. A project switches on the method and the
stack it uses, and every repo then reads the same version of each skill instead of a copy that drifts.

## Plugins

| Plugin | Level | Skills |
|---|---|---|
| `method` | | `spec-interview`, `plain-writing`, `code-comments`, `design-principles`, `feature-review`, `safe-changes`, `pre-pr-checklist` |
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

## Credits

- `spec-interview` takes the idea of a relentless planning interview from Matt Pocock's `grill-me` skill
  ([mattpocock/skills](https://github.com/mattpocock/skills)). The text and the decisions-table output are mine.
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

The same scan guards my public app repos. Their history already holds findings that the whole-tree scan would
report on every push, so there it runs with `--pushed`, which scans only the lines the pushed commits add.

- A copy of the script at `scripts/check-public.sh`, identical to this one.
- `.githooks/pre-push` with `exec scripts/check-public.sh --pushed`, enabled once per clone with
  `git config core.hooksPath .githooks`.
- An optional `.check-public` file at the top of the repo, one directive per line: `ignore <glob>` for
  lockfiles and seed data, `allow-name <regex>` for a deny-list name the repo publishes on purpose (its own
  domain), and `warn <label>` to report a check without failing the push (`warn em dash`).

## Validate

```bash
claude plugin validate .
claude plugin validate plugins/method
```

## License

MIT, see [LICENSE](LICENSE).
