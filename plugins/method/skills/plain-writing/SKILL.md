---
name: plain-writing
description: >
  Removes the stylistic tics that make text read as AI-generated. Use it every time you write text that someone
  other than the person in the chat will read: UI strings, error and confirmation messages, empty states and
  toasts, comments and doc comments, README and docs, commit messages, PR and issue bodies, reports, log
  messages. It applies when the text is only part of a larger task (you are writing code and put comments in it)
  and when nobody asked about style.
---

# Writing without AI tics

## Why the rules are mechanical

A model writes in one pass, without rereading the whole: it does not notice it used the same construction three
times. Post-training also rewards prose that *looks* well written, so some figures became the default choice at
equal content. You cannot judge by feel whether a text sounds generated, because your default is the thing to
avoid. Apply the bans below as syntactic checks, then do the pass in section 5.

## 1. Banned constructions

| # | Pattern | Do not write | Write instead |
|---|---------|--------------|---------------|
| 1 | Reveal: a flat premise, then `:` or a dash, then a punchline | `It's the last step: the data is gone.` | Two sentences, or an explicit clause: `The last step deletes the data.` |
| 2 | Aphoristic closer that restates the sentence before it | `…a cache that never expires is a leak.` | Delete it. No fact, no sentence. |
| 3 | `not X, but Y` and its variants (`it's not about X, it's Y`, `not just X but Y`, `X, not Y`) | `This isn't a bug, it's a configuration problem.` | State Y alone: `The configuration is wrong.` |
| 4 | Echo for rhythm: the same root twice in one sentence | `Removing it removes the whole thread.` | Vary the word or split the sentence. |
| 5 | Tricolon built for cadence, not because there are three | `fast, reliable and scalable` | List what exists, with the criterion. |
| 6 | Evaluative adjectives without a number (`robust`, `powerful`, `significant`, `seamless`) | `A significant performance improvement.` | The number: `p95 from 400 ms to 90 ms.` No number, no adjective. |
| 7 | Dropped referents for density | `…and the one it answered.` | An explicit subject, even if longer. |
| 8 | Rhetorical opening question | `Ever wondered why…?` | Start from the fact. |
| 9 | Decorative metaphor for a mechanism | `The queue is like a restaurant kitchen…` | The mechanism. |
| 10 | Closing summary (`In short`, `The bottom line`, `Ultimately`) | | Delete it. The text has already ended. |
| 11 | Emphasis on ordinary words (scattered bold, knowing quotes) | `a **truly** different approach` | No emphasis, or emphasis on domain terms only. |

The ban is on the rhetorical move (premise, pause, twist), not on the character. A colon that introduces a list
or a value is fine.

**Other languages.** The same moves exist everywhere. In Italian the reveal usually comes after a colon or a
spaced en dash, and `non X, ma Y` is the most frequent form of rule 3.

## 2. Positive rules

- One fact per sentence.
- An explicit subject when the antecedent is more than a sentence away.
- Concrete verbs: `returns`, `deletes`, `rejects`; not `handles`, `manages`, `deals with`.
- Numbers instead of vague quantities (`3 replies`, not `the replies`).
- A measured claim carries its evidence: the sample size, the interval, the seed or the command that reproduces
  it. "Faster" or "beats" without a measurement is not a claim.
- A flat, literal register on anything destructive or irreversible, and on anything about money, grades or
  health. Liveliness there is a defect.
- If a sentence can be deleted without losing a fact, delete it.

## 3. Interface text

Before handing over a string, check that it carries what the user needs to decide.

- **Confirmation dialog.** What is touched, how much (the exact number), whether it can be undone, and what is
  *not* touched when that is not obvious. The button carries the verb of the action (`Delete`), never `OK`.
  Confirm only what is rare and irreversible; what is frequent and reversible gets an undo instead.
- **Error.** What failed, why if you know, and what the user can do now. No apologies, never a bare
  "Something went wrong".
- **Empty state.** Why it is empty and the action that fills it. No jokes.
- **Success toast.** What changed and where to find it.
- **One object, one name** across the whole product. Never a synonym for variety.
- **Several languages.** Each message file carries the same facts. Translate the meaning, not the words.

The project's own voice (a `DESIGN.md`, a style section in `CLAUDE.md`) adds to these rules: person, register,
punctuation, how counts are written.

## 4. Comments, docs and logs

Whether a comment should exist and where it goes is the `code-comments` skill. Here only how it reads: a doc
comment ends up in an editor tooltip, so rules 1–4 and 6 apply with no exceptions, and a comment states a fact,
never a moral.

Log messages are templates: a fixed sentence with named properties, no string interpolation, no adjectives.
`Rejected order {OrderId} with status {Status}` can be searched and grouped; a sentence built by concatenation
cannot.

## 5. Mandatory review pass

Before delivering, reread the output looking for these markers. Do not skip it because the text is short.

- [ ] `:` or a dash introducing a punchline → rewrite
- [ ] `not … but`, `not just … but`, `X, not Y` → rewrite
- [ ] The same root twice within 15 words → rewrite
- [ ] The last sentence of each paragraph: does it add a fact? If not → delete
- [ ] Evaluative adjectives without a number → delete or quantify
- [ ] Lists of exactly three → check they are three by necessity
- [ ] Every pronoun and ellipsis: is the antecedent less than a sentence away? If not → make it explicit
- [ ] Subject–verb and singular–plural agreement on every sentence rewritten halfway

## 6. When the rules are suspended

- The user explicitly asks for another style, or for creative prose.
- Quotations and text that must stay verbatim.

## Examples

**Confirmation dialog**

✗ `It's the first message: its replies go too.`
The reveal (1), a vague verb on a destructive action, a dropped referent (7), and it says neither how many nor
whether it can be undone.

✓ `This is the first message of the thread. Its 3 replies will be deleted too. This cannot be undone.`

**Doc comment**

✗
```ts
/**
 * Per workspace, not per user: the same person can be an admin in one workspace and a viewer in
 * another, so storing it on the user would make one of them wrong.
 */
role: roleEnum(),
```
`X, not Y` (3), the reveal after the colon (1), a rationale in a contract, and three lines.

✓
```ts
// The same person can hold a different role in each workspace.
role: roleEnum(),
```
