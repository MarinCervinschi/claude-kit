---
name: feature-review
description: >
  A fixed review pass after a new feature or a UI change: delimits what changed, runs the app on local data,
  checks the touched screens for accessibility, layout, copy and design problems with the review skills that are
  installed, merges every finding into one table by severity, fixes the confirmed ones and checks again in a
  browser. Stops before committing. Use it when the user asks for "the usual review", a check of a feature, a
  hunt for inconsistencies, bugs or design and accessibility problems, or invokes /feature-review.
---

# Feature review

A full review of what changed, then the fixes. It stops before any commit: committing is the user's call.

## 1. Delimit the scope

- Find the touched files: `git status --short` and `git diff --stat`, or the range the user gives.
- Find the **screens** that show them (routes, pages, components) and the **states** to see: empty, loading,
  error, signed out, signed in, each role, a phone at 320 and 375 px, the dark theme.
- Write the scope in one line and keep to it. Say what stays outside it; never report it as checked.

## 2. Run the app on local data

- Start the app against a **local** database. Read the project's `CLAUDE.md` for the right command: if the usual
  dev command reads real secrets or a production database, use the local one instead.
- Seed what the screens need, with data that cannot be mistaken for real (reserved codes, `example.com`
  addresses).
- If the project has a `.claude/launch.json`, start the local configuration from there.

## 3. Automated checks

Run what the project already has, from the commands table in `CLAUDE.md`: format, lint, typecheck, tests. A design
linter or a page inspector, if the project uses one, runs on each route in the scope, including routes with
parameters. Add one route outside the scope as a reference: if it fails there too, the problem is not this
feature's.

Open every screenshot an inspector produces and look at it. A problem you can see is real, whatever the code says.

## 4. Review skills

Load the review skills that are installed and pass the touched files and screens through each. These work well
together, all third-party:

- `taste-skill` (design taste, lint and inspect), in review mode only: no redesign.
- `ui-ux-pro-max`, by its priorities: accessibility, touch and interaction, layout, forms and feedback,
  navigation.
- `interfaces`: `better-interface` first, then its six domain skills (accessibility, layout, writing,
  typography, colors, UI).

A skill you did not load is a domain **not checked**, never a domain that is fine. Say which ones ran.

Whatever is installed, always look for these, and rate them **HIGH**:

- a control with no accessible name;
- no visible focus;
- a destructive action with neither a confirmation nor an undo;
- content cut off, or a horizontal scrollbar, at 320 px;
- an error that does not say how to recover;
- meaning carried by color alone;
- motion that ignores `prefers-reduced-motion`.

Also look for: a slow action with no loading state; a field the browser would fill with personal data, missing
its `autocomplete`; a color token used for a role it was not made for (a "text" color used as black, which turns
light in the dark theme).

Copy follows the project's voice (`DESIGN.md` or equivalent) and the `plain-writing` skill.

## 5. Merge, show, fix

- **One table** for all the sources: severity, `file:line`, problem, fix. One cause is one row, listing every
  place it appears. HIGH first, then by how many places one fix repairs.
- Drop personal taste: a choice the project's design doc made is not a problem.
- Fix the confirmed problems with the project's own tokens, components and helpers, then run the formatter on the
  touched files.

## 6. Check again

- Typecheck and tests; the build too if dependencies, asset imports or configuration changed.
- Rerun the linters and inspectors until they report **0 failures**. A warning stays only if you can defend it in
  one sentence.
- In the browser: every state in the scope, at 320 px (resize to 320×700 and check that
  `document.documentElement.scrollWidth` stays 320), at 375 px, then back to desktop.
- **Flows that need a role**: use a test user in the local database only. Grant the role for the check, then put
  it back and delete the test data. If the auth library caches sessions, force a refresh after each change, or
  the old role stays in effect.

## 7. Report

In the user's language, short:

- what was checked: screens, states, skills loaded;
- the table, with what was fixed and what was left and why;
- the final numbers (lint, inspect, tests);
- what could not be tested (a real camera, an external service, a payment), said plainly.

No commit. The user decides.
