---
name: pre-pr-checklist
description: >
  The pass before a change becomes a commit or a pull request: reads the diff, runs the project's checks and
  reports their real output, looks for secrets, leftovers and stale docs, then drafts a terse commit message and
  PR body that say what was verified and what was not. Use it when the user says "ready for a PR", "prepare the
  PR", "check before I push", "write the commit message", or when a piece of work is finished.
---

# Before a PR

The goal is a change a reviewer can trust without rerunning it: one coherent change, checked, described in a few
lines, with what was **not** checked said as plainly as what was. This skill prepares the commit and the PR; it
does not create, push or open anything unless the user asks.

## 1. Read the diff

- `git status` and `git diff` (or `git diff <base>...HEAD` for a branch). Read all of it, not the stat.
- **One coherent change.** If the diff mixes unrelated work, propose a split and stage it with `git add -p`.
  Never edit or revert working code to carve commits.
- Nothing generated, built or local: no `.env`, no build output, no lockfile churn the change did not need.

## 2. Run the checks

Take the commands from the project's `CLAUDE.md` (format, lint, typecheck, tests, build) and run them. Report the
real output: the command, pass or fail, and the failing lines when there are any. A failing check is reported,
never hidden and never "probably unrelated" without a reason.

If the change touched the UI, the `feature-review` skill is the pass for it. Looking at the screens is the
human's job unless that skill ran.

## 3. Look for what checks miss

- [ ] **Secrets**: tokens, keys, passwords, connection strings, private IPs and hostnames, internal IDs. Not in
      code, tests, fixtures, docs or the commit message.
- [ ] **Leftovers**: debug prints (`console.log`, `dbg!`, `print`), focused or skipped tests (`.only`, `.skip`),
      commented-out code, TODOs without an issue.
- [ ] **Comments** pass `code-comments`; **prose** (docs, messages, UI strings) passes `plain-writing`.
- [ ] **Migrations and API changes** pass `safe-changes`.
- [ ] **Docs that describe what changed** are updated in the same change: the `CLAUDE.md` router (commands,
      layout, rules), `SPEC.md` (a new or revised decision, dated), the README, an ADR for a decision with
      consequences, the changelog for anything a user notices.
- [ ] **Tests** cover the new behaviour where they pay off (see `design-principles`), and a fixed bug has a test
      that would have caught it.

## 4. The commit message

- Conventional Commits, in English: `feat:`, `fix:`, `refactor:`, `docs:`, `test:`, `chore:`, with a scope when
  the project uses them.
- A plain subject that says what changed, in the imperative, no full stop. Usually enough on its own.
- A body only when the why is not obvious from the subject and the diff.
- No attribution lines for tools.

## 5. The PR body

Short. A reviewer reads it in under a minute.

```markdown
<What changed and why, in one to three sentences. Link the issue.>

**Checked**
- `pnpm typecheck`, `pnpm test` (212 passed), `pnpm build`
- The import on a local copy of production data: 1,204 rows, 0 rejected

**Not checked**
- The email flow: no SMTP in the local setup
```

- **Checked** lists commands and what they returned, not adjectives.
- **Not checked** is never empty by omission. If everything was checked, say "nothing left out".
- No screenshots of passing tests, no changelog of every file, no "this PR" preamble.

## 6. Stop

Show the commit message and the PR body. Commit, push or open the PR only when the user asks, and confirm each
commit.
