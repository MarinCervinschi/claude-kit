---
name: grill-me
description: >
  Interviews the user about a plan, a design, a decision or a task until nothing that matters is left assumed,
  with as many questions as the subject needs and no more. Sizes the subject first, asks the open decisions in
  numbered rounds with a recommendation each, looks facts up instead of asking for them, and ends with the
  decisions, their reasons and the open questions, written where they belong once the user agrees. Use it when
  the user says "grill me", "interview me", "stress-test this" or "help me decide", and when another skill needs
  an interview.
---

# Grill me

An interview that turns a plan into decisions the user has taken, each with its reason. It asks only what the
user has to decide, in as few rounds as the subject allows.

Adapted from Matt Pocock's `grill-me` and `grilling` skills ([mattpocock/skills](https://github.com/mattpocock/skills),
MIT). The design tree, the rounds over the frontier and the split between facts and decisions come from there.
The sizing step, the assumptions list and where the decisions are written are this kit's.

These are defaults. The user's instruction for the session wins: one question at a time, a shorter session, no
write-up at the end.

## 1. Size the subject before the first question

Read what already exists: the issue, the repo with its `CLAUDE.md` and `SPEC.md`, the docs, the conversation so
far. Then sort every open point into one of four kinds.

| Kind | What it is | What to do |
|---|---|---|
| Settled | the context already answers it | use the answer; mention it only if the user may not know it |
| Fact | something the environment can answer | look it up (section 3) |
| Default | a choice with an obvious answer that is cheap to change later | don't ask; list it with the assumptions at the close |
| Decision | the user's call: it is costly to reverse, or it trades one thing for another | ask it |

The number of decisions sets the size of the session. Say it in one line before the first question, for example
"I see 3 open decisions, independent of each other."

| Decisions | Session |
|---|---|
| none | no interview: list the assumptions and ask for one confirmation |
| 1 to 5 | one round; a second only if the answers open new branches |
| more, or chains of dependent choices | rounds over the frontier (section 2) |
| several areas that could each fill a session | propose splitting the subject first, then grill one piece |

A small task can need no interview at all. Never turn a default into a question to look thorough.

## 2. Ask

Model the subject as a tree: each decision has the decisions that hang off it. The frontier is every decision
whose prerequisites are settled. A round asks the frontier and waits for the answers. A question that depends on
an answer still open waits for a later round. After each round, recompute the frontier: settled decisions unblock
new questions, and an answer can make other questions moot.

Speak the user's language: the language of their own messages, or the one the project uses with them. A brief
written by another session or skill does not set it.

There are two ways to ask a round. The user's instruction or their personal settings choose; without either, ask
the whole round in one message.

**The whole round in one message.** Number the questions so the user can answer by number ("1 yes, 2 the second
option, 3 no because ..."):

```markdown
**Q1. <title>**: <the question, the options and what each one costs>
→ <the option you recommend, and why, in one line>
```

**One question at a time.** Ask the round's questions one per message and wait after each. A single question has
room for its context: what is at stake, the options and what each one costs, the recommendation and why. Close it
with the question itself, worded for a yes or a no.

Either way:

- Word each question so that "yes" accepts the recommendation. If the recommendation argues against the
  question as worded, reword the question.
- A message that asks holds the questions and the context they need, nothing else. The assumptions wait for the
  close (section 5).
- Use the harness's interactive question tool (`AskUserQuestion` in Claude Code), when there is one, for short
  closed questions that a one-word answer settles. Its options leave little room for context, so a choice that
  needs explaining is asked in the message text.
- Push on vague answers. "Fast" gets "how fast, measured how". Ask again until the answer can be checked.
- When an answer closes a door (no accounts, no offline, one language), name the door in one sentence.
- When a decision is about something that runs without the user (a routine, a scheduled job, a hook), the
  question also says how its result reaches them: where the report lands, what notifies them, what happens when
  it fails.
- Write no code during the interview. A sketch of a type or an endpoint is fine when it helps a decision.

## 3. Facts are yours, decisions are the user's

- Never ask the user something you can find out. Read the files, run the read-only command, check the tracker.
- Give a wide lookup to a subagent and ask the rest of the frontier meanwhile. Only the questions that depend on
  the lookup wait for it.
- Never answer a decision yourself, even when the recommendation looks obvious. An interview where the agent
  answers its own questions records the agent's opinion as the user's decision.

## 4. Keep it a conversation

The user owns the scope. Say when the scope drifts, and say when the session grows past the size announced in
section 1.

- "I don't know" is a valid answer. Record it as an open question, with what would settle it.
- Some questions cannot be settled by talking: how a screen should look or feel, how a system behaves under real
  load. Stop asking about them. Propose the smallest prototype or measurement that would answer, and record the
  question as open.
- A whole round accepted with one "yes" is fine. On a decision that is hard to reverse, ask once for the user's
  reason if they gave none.

## 5. Close

The session ends when the frontier is empty or the user says to stop. Then show, in the language of the chat:

1. **Decisions**, one line each with its reason. With more than three, a table with number, decision, why and
   date.
2. **Assumptions**: the defaults applied without asking, for the user to correct.
3. **Open questions**, each with what would settle it.
4. **Where to write the decisions down.** Propose the place; write only after the user agrees.
   - The issue where the work lives, as a dated comment ("Decided on 2026-10-30: ...").
   - The decisions table in `SPEC.md`, when the project has one.
   - The project's `CLAUDE.md`, for a rule that must always hold.
   - Nowhere, when the work is small and gets done in this session.

   A decision earns a lasting record when it is hard to reverse, surprising without its context and a real
   trade-off. The others can stay in the issue comment or in the conversation.
5. **The next step, sized to the work.**
   - A few changes for this session: offer to make them.
   - One piece of work for later: one issue, if the project tracks work in issues.
   - Several pieces, or more than one session: an epic with issues, following `method:task-tracking`. Show the
     text first and create the issues only on a yes.

Do not act on the result until the user confirms that the understanding is shared. The "why" of every decision
is the user's reason, compressed. Never invent one.

Everything shown or written at the end follows `method:plain-writing`.
