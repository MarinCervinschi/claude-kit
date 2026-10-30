---
name: task-tracking
description: Plan and track work as projects, epics, issues and sub-issues on Linear or GitHub, written so that a person or an agent can pick any task up cold. Covers issue shapes, done criteria, keeping issues current, status flow, branches, pull requests and status updates. Use when creating or updating issues, epics, projects or status updates, or when turning a spec's milestones into tasks.
---

# Task tracking

**These are defaults, not rules.** They change from project to project and from task to task. The project's own conventions (its `CLAUDE.md`, its existing issues) and the user's instruction for the task always win. When a case is not covered, or a default looks wrong for it, ask.

## Before creating anything

- A tracker is shared: other people see what you create. Create or edit issues, projects and status updates only when the user asked for it, and show the text first when in doubt.
- Search for an existing issue on the same subject, and link to it instead of duplicating it.
- Find the parent (project, epic or umbrella issue) the new work belongs to.

## The model

| Level | Linear | GitHub |
|---|---|---|
| Initiative with an end | project, whose description is the design document | epic issue (label `epic`), or a spec milestone |
| Umbrella | parent issue | epic with children |
| Unit of work | issue or sub-issue (up to three levels) | child issue, first line "Part of #N." |
| Done criteria | checkboxes in the description | checkboxes under "Done when" |
| Effort | estimate | a footer "Effort: S/M/L/XL · Risk: low/medium/high", or the board's Size |

Choosing the shape:
- **A big epic gets real sub-issues**, so the tracker shows progress by itself. **A small one**, with a few items that ship together, keeps a checklist in its body.
- **Say what an estimate means** when siblings are estimated: effort, or the order to do them in.
- **File a roadmap in one go** into the backlog, then pull items into the current cycle when work starts.
- **A spec milestone can become an epic**, with the milestone's "done means" as the epic's done criteria and its steps as children.

## Writing an issue

Open with one paragraph of plain context: what and why. Then the sections the issue needs.

| Kind | Sections |
|---|---|
| Bug | what is observed, the cause (file and function), the fix or the steps, notes; measure the damage when you can |
| Feature | the proposal, done criteria |
| Domain task | goal, the domain rule, decisions (a table), current state, steps, references |
| Idea for later | the idea, the goal, what to find out |
| Field or ops work | what to install or run, what to check on site, the expected outcome |
| Analysis | findings by severity, no fixes yet, open points |
| Child of an epic | "Part of #N.", dependencies, context, scope checklist, notes, effort and risk |

Habits that make an issue resumable:
- **Evidence over adjectives**: identifiers in backticks, counts, measurements, the document section you rely on.
- **Done criteria as checkboxes**, ticked as the work lands.
- **Titles**: "Area: what" for most work; a bug titled by what is observed; a task that starts with a verb.

## Keeping it current

- A decision gets a dated comment ("Decided on 2026-10-12: ...") in the issue where the work is.
- When the spec changes, add a dated note: what was dropped, what was added, what is now risky. Strike a revised scope item through instead of deleting it.
- Close with a summary comment that says what was done and what moved to which other issue.
- A dropped plan is closed as not planned, with a one-line reason and a link to whatever replaced it.

## Flow, branches and pull requests

- **Statuses**: backlog, in progress, in review (pull request open), done (merged). Use the tracker's own states; don't invent new ones.
- **Branch**: the tracker key on its own (`ABC-123`), or `<number>-<slug>` on GitHub. Follow the project's existing names.
- **When a pull request**: features and risky changes go through a branch and a pull request. Small fixes and docs can go straight to the integration branch when the project allows it, with the issue number in the commit message.
- **Pull request title**: Conventional Commits, with the tracker key when there is one.
- **Pull request body**: what changes and which issue it belongs to ("Closes #N", "part of ABC-120"), one bullet per component, how it was verified, then release notes when the deploy needs anything (migrations, secrets, order of steps). Run `method:pre-pr-checklist` before opening it.
- **Release**: when the project versions its releases, one release pull request per version, with the changelog entry written at that point.

## Status updates

About once a week on a project that is moving: one line when little changed ("in review", "merged to staging"), otherwise a short report with what is done, the next steps and what to watch. Keep health and target dates honest, or leave them empty.

## Language and style

- Write in the tracker's language. Unless the project says otherwise: the team's language on a team tracker, English on GitHub. Domain nouns can stay in the original language.
- Code, commits and pull requests in English.
- All prose follows `method:plain-writing`: one fact per sentence, numbers instead of adjectives, no em-dash.
