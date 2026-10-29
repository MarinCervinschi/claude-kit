---
name: design-principles
description: >
  How code is structured: module boundaries, SOLID as it applies to Rust, Python, TypeScript and C#, which design
  patterns fit and which do not, error handling, determinism, and where tests pay off. Use it before adding a
  module, package, crate, project, interface, trait or Protocol; when deciding whether something deserves an
  abstraction; when a file or function grows; and when reviewing a change for structure. Requests that sound like
  "where does this go?", "should this be an interface?", "is this over-engineered?" or "refactor this" all land
  here.
---

# Design principles

Code gets read, rerun and extended months later. The bar: a new feature, a new variant or a new screen is added
by **writing new code**, not by editing the core. The rules below say how to keep it that way without building
abstractions nobody uses.

## 0. YAGNI comes first

Every rule below applies to the code that exists **today**, not to the code a later milestone might need. When a
principle and YAGNI disagree, YAGNI wins and the principle waits for the change that needs it.

- Build what the current milestone needs. A later milestone in `SPEC.md` is a reason to keep a door open (no
  global state, a constant instead of a literal), not a reason to build the room.
- No interface, generic, config option, feature flag, plugin point or folder for a single case.
- No public API "in case". Export only what a caller uses now; a new caller can widen it.
- Prefer the boring version: a function over a type, a type over an interface, a `switch` over a registry until
  there are enough cases to need one.
- Refactor when the second case arrives, with the second case in hand. Tests make that cheap.
- "This is over-engineered" is a valid reason to delete code in review, even when the code follows a pattern
  from this skill.

## 1. Boundaries

Draw the project's layers in `CLAUDE.md`, one line each: what the layer owns and what it may call. For example:

```
core/        the rules of the domain        knows nothing about the web, the database or other languages
adapters/    bindings, HTTP, persistence    translation only
app/, web/   the entry points               call the core through the adapters
```

- Dependencies point inward. The core has no flags or branches for its callers.
- An adapter converts types and errors and does nothing else. A domain rule in an adapter, a controller or a
  component is a bug: move it into the core and call it.
- Keep the core free of I/O, clocks, threads, global state and ambient randomness when it has to run in more than
  one place (a server, a worker, a browser, a test). Pass those in.

## 2. SOLID, as it applies here

**Single responsibility.** One concept per module. A module whose one-line description needs "and" is two
modules. A file past about 400 lines or a function past about 50 is a signal to look, not an automatic split.

**Open/closed.** The core is closed; the variants are open. A new variant is a new type in its own module, and
nothing in the core changes for it. Choosing a variant by name happens in **one** registry at the edge (a CLI, an
adapter, a DI registration), never in a `switch` spread across the codebase.

**Liskov.** Every implementation of an interface honours the same contract. When there are several, one shared
contract test runs each of them through the same cases.

**Interface segregation.** Each consumer gets the narrowest view that serves it. Do not add a field to a shared
type because one consumer finds it handy; derived knowledge goes in a function, not a new field.

**Dependency inversion.** Depend on an interface only where there is a real seam:
- two or more implementations exist, or the spec names the second one, or
- the boundary crosses a language, a process or the network.

An interface with one implementation "for testing" or "for the future" is not a seam.

## 3. Patterns that fit

| Pattern | Use it for | Shape |
|---|---|---|
| Strategy | interchangeable algorithms or policies | an interface plus one type per strategy |
| Adapter | bindings, HTTP clients, persistence | a thin layer, types in, types out |
| Registry / factory | choosing an implementation by name | one table at the edge |
| Value object / newtype | identifiers, money, units, validated strings | invalid states unrepresentable |
| Event log | history, audit, results | append-only records that can be replayed |
| Immutable snapshot | configs, views handed to consumers | built once, never mutated |

Patterns that do **not** fit, and what to do instead:

- Singletons, globals, mutable statics → pass the value in.
- Inheritance hierarchies and abstract base classes → interfaces and composition.
- Builders for types with three fields → a constructor or a literal.
- `Manager`, `Helper`, `Utils` modules → name the concept the code is about.
- A generic framework for cases the project does not have → write the concrete case.

## 4. When to add an abstraction

Add it on the **second** real use, extract it on the **third** (rule of three). Before that, duplication is
cheaper than the wrong abstraction. Ask: does the spec name a second implementation? Does a caller in another
language or process need it? If neither, write the concrete code.

## 5. Language idioms

**Rust**
- Closed sets are `enum`s; identities are newtypes. Fields private, `pub` only what a caller needs.
- `Result` for anything a caller can cause and handle. `panic!` and `expect` only for a broken internal
  invariant, and the `expect` message states the invariant.
- No `unwrap()` in library code outside tests.
- `cargo clippy --all-targets -- -D warnings` and `cargo fmt` are the style guide.

**Python**
- Typed: every public function has annotations, and a type checker runs in CI.
- Configs and results are frozen `dataclass`es. No dict-shaped data across module boundaries.
- Interfaces are `Protocol`s, not ABC trees.
- Notebooks and scratch folders are scratch: anything another module imports lives in the package and follows
  these rules.

**TypeScript**
- `strict` on. Closed sets are string unions; messages between processes or workers are discriminated unions,
  typed on both sides.
- Validate at the edge (zod or equivalent), then trust the types inside.
- Components render. State comes from one hook or store, never recomputed inside a component.

**C#**
- Nullable reference types on, warnings as errors in CI.
- Value objects are `record`s or `readonly record struct`s; identities get their own type.
- Expected failures a caller can handle are part of the return type; exceptions are for broken invariants and
  infrastructure failures. Pick one convention per project and write it in `CLAUDE.md`.
- Constructor injection only. No service locator, no static access to the container.

## 6. Determinism

Anything that is measured or replayed is reproducible from its inputs. Randomness comes from an injected seed or
generator, time from an injected clock. A run records its seeds, its version and its config. Iteration order that
feeds a random generator is fixed (sorted keys, never hash-map order).

## 7. Tests: where they pay off

- **The core's rules**: the critical path. Hand-checked cases, a hand-traced reference run, property tests over
  many seeded inputs.
- **Every implementation of an interface**: the shared contract test.
- **Statistics and money**: cases with a known answer.
- **A bug just fixed**, so it does not come back.
- **Not** getters, constructors that assign fields, plain conversions in adapters, or the shape of a UI.

Test names say the behaviour (`expired_token_is_rejected`). A test that uses only the public API lives with the
other public-API tests; one that needs private items sits next to them.

## Before you call it done

- [ ] Nothing built for a case that does not exist yet (YAGNI)
- [ ] No domain rule outside the core
- [ ] New behaviour added as new code, not as a branch in the core
- [ ] Every new interface, trait or Protocol has two implementations or crosses a boundary
- [ ] Every random choice and every clock read comes from an injected source
- [ ] Errors a caller can cause are part of the contract; panics and exceptions name the invariant
- [ ] Comments pass `code-comments`
