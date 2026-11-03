---
name: docs
description: >
  How a project keeps its documentation and how agents read it: a `docs/` folder of Fumadocs pages (`.mdx` and
  `meta.json`) organized by subject, read through the `docs` CLI one section at a time instead of whole files,
  and checked with `docs lint` before a commit. Use it when a question is about how the project works and the
  repo has a `docs/` folder, when you write, move or rename a page, when you learn a fact that belongs in the
  docs, and before committing a change under `docs/`.
---

# Docs

A project documents itself in a `docs/` folder at the root of its repo, in the Fumadocs content format. The
folder is the content; how a site shows it (a docs app, a page inside the product, no site at all) is the
project's choice and does not change the files.

| File | What it holds |
|---|---|
| `SPEC.md` | the decisions and their reasons |
| `CLAUDE.md` | the rules and the routing for agents |
| `docs/` | the reference: how each part works, with the reasons behind it |
| `README.md` | the entry for a visitor: what it is, how to start |

## Reading: the `docs` CLI

`docs` reads the folder the way Fumadocs does and returns only what was asked. Install it once per machine with
`npm install -g @marincervinschi/docs` (Node 22 or later). A page is its path in `docs/` without the extension
(`hardware/pins`); its URL and `page#anchor` work too.

| To | Run |
|---|---|
| see what the docs cover | `docs outline` |
| see one page's sections and their sizes | `docs outline hardware/pins` |
| read one section | `docs page hardware/pins#the-header` |
| find the page when you do not know it | `docs search <words>` |
| see what links to a page before moving it | `docs links hardware/pins` |
| check the folder | `docs lint` |

- Go from the map to the section: `outline`, then `outline <page>`, then `page <page>#<anchor>`. Read a whole
  page only when you are about to edit it.
- `docs help` lists every command in under 300 tokens; `docs help <command>` gives its options.
- From another repo, add `--dir <path to the repo>`.
- The output is one line per item, the page or `page#anchor` first. `--json` gives the same data to a script.

**Read the docs only through `docs`.** Do not open or Grep files in `docs/` to look something up: a Grep over
the repo returns lines out of their section, and a whole page costs more than the section you need. The file
tools stay allowed on `docs/` because editing a page needs a read first and `docs` does not write: Read a page
only to edit it, and give Grep a path outside `docs/` when you search the code.

## Writing a page

- **Organize by subject**: the parts of the system (`hardware/`, `firmware/`, `api/`), one page per thing a
  reader looks up. Reference tables and the reasons behind them go on the same page. A page shaped as a task
  only where the reader arrives with one: troubleshooting (symptom, cause, fix, each with its date), setup.
- **Frontmatter**: `title` (Fumadocs requires it) and a one-sentence `description` that says what the page
  answers. `docs outline` and `docs search` show both.
- **Headings are the anchors agents ask for.** Make them short, specific and unique in the page (`## The
  header`, not `## Details`). A heading whose text may change gets a fixed anchor: `## First run [#first]`.
- **Plain Markdown first**, with GFM tables. An MDX component only when Markdown cannot say it. Outside code,
  `<` and `{` start JSX and expressions: put them in code or escape them.
- **Links between pages** as site paths (`/docs/hardware/pins#the-header`) or relative files
  (`./pins.mdx`). `docs lint` resolves both.
- **Date what can go stale** ("2026-11-03"). A fact learned while working goes into the page it belongs to,
  with its date, in the same piece of work.
- **Vendor documents** (datasheets, manuals): link them and summarize in your own words. Do not copy them into
  the repo.
- The prose follows `method:plain-writing`.

## `meta.json`

One per folder sets the folder's title and the order of its pages:

```json
{ "title": "Hardware", "pages": ["board", "pins", "display"] }
```

- A new page goes into its folder's list, unless the list ends with `"..."`, which adds the rest. A page left
  out does not appear in the navigation, and `docs lint` reports it.
- `"---Title---"` is a separator, `"[Text](https://…)"` a link, `"!page"` hides a page on purpose.
- A folder without `meta.json` lists its pages alphabetically, titled after the folder.

## Before committing

1. `docs lint` exits with 0: every page has a title, the MDX compiles, every link and anchor resolves, and
   `meta.json` matches the files.
2. After moving or renaming a page or a heading, `docs links <page>` lists the pages that link to it. Fix them
   in the same commit.

## In the project's `CLAUDE.md`

One line in the skill routing sends questions to the docs:

```markdown
- A question about how the project works → the docs, read with the `docs` CLI (`method:docs`): `docs search` or
  `docs outline`, then `docs page <page>#<anchor>`. Do not Read or Grep files in `docs/` to look something up;
  Read a page only to edit it. A fact learned while working goes into its page, with its date.
```
