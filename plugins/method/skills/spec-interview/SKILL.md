---
name: spec-interview
description: >
  Interviews the user until a project or a large feature has no open decision left, then writes `SPEC.md`: a
  numbered decisions table with a Why column, the architecture, milestones and the open questions. Use it when
  starting a new project or a feature big enough to need a plan, and when the user says "grill me", "interview
  me", "spec this", "help me decide" or "what do we need to decide first".
---

# Spec interview

A project starts with decisions, not code. This skill asks the questions one at a time, pushes on every vague
answer, and writes each decision down with the reason the user gave. The result is `SPEC.md`, the first file of
the repo, which the `CLAUDE.md` router and every later session read.

The idea of an interview that keeps asking until the plan has no gaps comes from Matt Pocock's `grill-me` skill
([mattpocock/skills](https://github.com/mattpocock/skills)). This is a separate text, with its own output: the
decisions table.

## How to ask

- **One question at a time**, or a small group when the answers depend on each other. Wait for the answer.
- **Offer a recommendation** with each question: the option you would pick, one or two alternatives, and what
  each one costs. The user decides; you never decide for them.
- **Push on vague answers.** "It should be fast" gets "how fast, measured how, on what". "Users" gets "who,
  how many, signed in or not". Ask again until the answer can be tested.
- **Look before you ask.** If the repo, an existing project or the docs already answer a question, read them and
  confirm instead of asking.
- **Name the consequence.** When an answer closes a door (no accounts, no offline, one language), say which door,
  in one sentence, and move on.
- **Do not write code** during the interview. A sketch of a type or an endpoint is fine when it helps a decision.

## What to cover, in this order

1. **Who and what for.** Who uses it, the one job it does for them, how they find it.
2. **Scope of the first release**, and what is explicitly out of it.
3. **The domain rules**: the few things that must always hold. They become the non-negotiable rules in
   `CLAUDE.md`.
4. **Data**: what is stored, who owns it, what is personal, what happens on deletion.
5. **Stack**: which named stack fits (a `stack-*` plugin from this kit, if one does), and what the project adds
   on top of it.
6. **Where it runs**: environments, secrets, backups, the cost of each piece. Decide per project; "no staging" or
   "no backup" are valid answers when they are written down.
7. **Auth, privacy and abuse**: accounts or not, roles, rate limits, what an anonymous visitor can do.
8. **How success is measured**: the number that says it works, and how it is collected.
9. **Milestones**: each one shippable, each one with a "done means" line. When one starts and the project tracks work in issues, `method:task-tracking` says how it becomes an epic.

## The decisions table

Record each decision as soon as the user makes it, not at the end.

```markdown
## Decisions

| # | Decision | Why | Date |
|---|---|---|---|
| 1 | Accounts are optional; voting works anonymously | Most visitors leave before signing up | 2026-10-26 |
| 2 | One container, migrations on start | One instance is enough for the expected traffic | 2026-10-26 |
```

- **Why** is the user's reason, compressed, in plain words. If the user gave none, ask for one. Never invent it.
- **Numbers are stable.** A later change does not renumber: it is recorded as a revision, with the date and the
  reason (`Decision 11 revised on 2026-10-28: …`), and the old text stays readable.
- One decision per row. A row that needs "and" is two rows.

## SPEC.md

```markdown
# <Project>

One paragraph: what it is, for whom, and the job it does.

## Decisions
(the table)

## Architecture
The pieces, how they talk, where each one runs. A diagram in text if it helps.

## Milestones
1. <name>: what ships. Done means: <a check anyone can run>.

## Screens            (if there is a UI)
One line per screen: what it shows, what the user can do there.

## Data model (draft)
Tables or types with their key fields and relations. A draft: the code becomes the source of truth.

## Open questions
- What is still undecided, and what would decide it.
```

## When to stop

Stop when every item in the first milestone has a decision, and everything still unknown is in **Open
questions** with what would settle it. Then:

1. Write `SPEC.md` (prose follows `plain-writing`).
2. Propose the first `CLAUDE.md`: a dated status line, the layout, a commands table, the non-negotiable rules
   from step 3, and which skills to load for which kind of change.
3. Show both to the user before the first line of code.
