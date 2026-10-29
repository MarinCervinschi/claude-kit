---
name: code-comments
description: >
  Use whenever you write or change a comment or a doc comment in any language: TSDoc and JSDoc, Rust `///` and
  `//!`, Python docstrings, C# XML docs, an inline `//` or `#`, a JSX `{/* */}`, a `--` in a SQL migration, a
  story's description. Decides whether the comment should exist at all, which form carries it, and the limits on
  length and language. For how the sentence itself should read, see `plain-writing`.
---

# Comments and doc comments

Two questions, in this order: **should this be written at all**, and **where does it go**. Most bad comments
fail the first one.

## Should it exist

The default is no. Delete a doc that repeats the identifier: `/** The user's id. */` on `userId` tells the
reader nothing the name did not. Silence is the right amount of documentation for a name that already says it.

A doc comment earns its place only when it carries something the signature cannot:

1. A precondition or invariant the caller has to respect (`must come from legalMoves()`).
2. The ordering, selection or comparison rule used (`in insertion order`, `the newest wins`).
3. What `null`, an empty collection or a sentinel means, and the unit, timezone, format or encoding of a value.
4. The error it throws or returns, and the input that causes it.
5. A cost that is not obvious: a query, a network call, an allocation in a hot loop, a large payload.

A project may add an item of its own that is always worth a line (in a game engine, whether a value is hidden
from a player). It says so in its `CLAUDE.md`.

If a comment you wrote is deleted in review, do not put it back. The explanation belongs in the commit message,
the PR, the issue or the chat.

## Where it goes

| What you want to say | Where |
|---|---|
| What a module or file is for | one line at the top (`//!`, a module docstring), only when the name does not say it |
| What an item is or does | the first line of its doc |
| A condition or constraint on it | the following lines of the doc, one fact per line |
| **Why** a line is written this way | a `//` or `#` on that line, or the commit message |
| A rule of the domain | the document that owns it (a spec, a rules file); the code may quote it, never extend it |
| Behaviour that lives in another module | nowhere: it is documented where it lives |
| How you got here, what you tried first | the commit message or the PR |
| Something to fix later | an issue, not the source |

The split broken most often is the fourth row. A rationale reads like it belongs in the doc and does not: the doc
is the contract the caller sees in a tooltip, and the caller can do nothing with a decision. Most rationale stays
out of the file altogether. A `//` survives only when the line would look wrong or redundant without it, so that
the next person would "fix" it.

## The hard rules

- **The first line is one sentence**, ending with a full stop. Editors and doc generators show it as the summary.
- **More lines only for the facts in the list above**, one fact per line. Anything else is a rationale or a story.
- **No section headers** (`# Examples`, `# Panics`, `Args:`, `Returns:`, `<remarks>`) unless the section has real
  content. A `# Panics` that says "panics if the invariant is broken" is noise.
- **No redirects** ("see X", "handled by Y", "owned by the sync", "#181"). Say what the item is. A link to another
  item is fine when the reader needs it to use this one.
- **No history.** Not "it used to be X", not "the first version did Y". That is the commit message.
- **No restating the code.** `// remove the item from the cart` above `cart.remove(item)` goes.
- **No section labels.** `{/* Header */}` above `<Header />`, `// Fetch the data` above a fetch: delete them.
- **English** in the code, migrations, tests and stories. Another language appears only in UI strings and in
  domain terms that have no English name.
- **No commented-out code.** Delete it; git has it.
- **No TODO without an issue.** `// TODO(#12): …` or nothing.

## Inline comments

Same test: only where needed, and about the **why**. The what is already the code.

```ts
// `ilike` reads `_` as a wildcard, and some codes contain one.
sql`lower(${products.code}) = ${code.toLowerCase()}`
```

That earns its place: without it the line looks like a needless rewrite of `ilike`, and someone would revert it.

```rust
let threshold = n.wrapping_neg() % n; // 2^64 mod n: draws below it would bias the low values
```

That one too: the line is opaque without it.

## By file type

| File | Rule |
|---|---|
| A doc on an export | the list above. A component whose props are typed and named well needs none |
| An ORM schema | no comment on a column whose name says it. A `//` only when its meaning is not its name: a unit, an external identifier, a value scoped differently from the row |
| A SQL migration | a `--` line only for a non-obvious data step. A generated migration needs none |
| A test | the test name is its doc. Comment inside a test only to say how the expected value was obtained (`// traced by hand`) or why an input was picked |
| A story | its doc renders as the story's description. One line, and only if the story name does not say it |

## Before you call it done

- [ ] Every doc that repeats its item's name → deleted
- [ ] Every doc line that is not a fact the caller needs → deleted, or moved to a `//`
- [ ] Every "why" in a doc comment → moved to a `//` next to the code, or out of the file
- [ ] Every history ("used to", "first version", "before #N") → moved to the commit message
- [ ] Every redirect to another module or issue → removed
- [ ] Every comment that restates the next line, and every section label → deleted
- [ ] Any non-English text outside UI strings and domain terms → translated
