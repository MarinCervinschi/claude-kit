---
name: overview
description: >
  The rust-py-lab stack: a dependency-free Rust core that owns the rules, a PyO3 binding through which Python runs
  measured experiments, and the same core compiled to WebAssembly for the browser. Its shape, core technologies,
  how the pieces talk, the rules that keep runs reproducible, and how to start a project with it. Use it when
  starting a simulator, a game engine, a rules engine or any lab where Python experiments and a browser share one
  core, or when working in such a project.
---

# Stack: rust-py-lab

A lab for measured experiments: one Rust core knows the rules, Python drives it, the browser runs it too.

## Shape

```
core/  (Rust, no dependencies)     the rules, the state, the agents or strategies
  ├─► py/    PyO3 binding (maturin)  ──► lab/ (Python, uv): experiments, statistics, training, reports
  └─► wasm/  wasm-bindgen binding    ──► web/: the browser, the core in a Web Worker
```

- **The core is the only place that knows the rules.** Python and the browser call it; they never reimplement a
  rule, however small.
- **Bindings translate only.** A binding converts types and errors and chooses implementations by name in one
  registry. A rule, a legality check or a score computed in a binding is a bug.
- **Python drives experiments** through the native module: many runs, statistics, training, tracking.
- **The browser runs the same core** compiled to wasm32, inside a Web Worker, with typed messages on both sides.

## Core technologies

- Rust (a Cargo workspace), PyO3 with maturin, the `wasm32-unknown-unknown` target with wasm-bindgen
- Python with uv; ruff, pyright in strict mode, pytest

An experiment tracker (MLflow or similar), a reinforcement-learning environment, a site framework: those belong to
the project.

## Rules that make it a lab

- **The core stays portable.** No threads, no clock, no filesystem, no OS randomness, no global state. Then it
  builds for wasm32 and PyO3 unchanged. Parallelism lives in the binding (rayon over many independent runs).
- **Everything is reproducible from a seed.** The core has its own small generator (for example xoshiro256** seeded
  by SplitMix64), so the same seed gives the same numbers on every platform. A run records its seeds, the core's
  version and its config.
- **Measure, don't eyeball.** Compare variants on paired runs (the same seeds for both sides, sides swapped when
  position matters), report the mean with a 95% interval, and call a winner only when the interval excludes the
  tie. Results are written from a clean tree, so the recorded commit is exact.
- **Strategies see only what they may see.** When the domain has hidden information, an agent receives an
  observation, never the full state.

## How to start

```bash
# the workspace
cargo new --lib core --name <app>-core   # in a Cargo workspace; a crate named `core` would shadow Rust's
cargo new --lib py --name <app>-py       # crate-type cdylib, depends on <app>-core and pyo3

# the binding, built into the lab's environment
cd lab && uv init --package && uv add --editable ../py   # maturin as py's build backend
uv add --dev ruff pyright pytest

# the browser build, when the site arrives
cargo build -p core --target wasm32-unknown-unknown
```

- `py/pyproject.toml` uses maturin as the build backend; `uv sync` rebuilds the binding when the Rust sources
  change.
- `wasm/` is added when the browser needs the core, not before.
- `[profile.test]` with `opt-level = 2` keeps slow searches testable, with overflow checks still on.

Layout and `CLAUDE.md`:

```
core/       rules, state, strategies     cargo test, clippy -D warnings, fmt
py/         PyO3 adapter                 translation only
wasm/       wasm-bindgen adapter         translation only
lab/        uv project                   pytest, ruff, pyright strict
web/        the site                     a web-ts static variant fits
```

The `CLAUDE.md` names the non-negotiable rules above in one line each, the commands per folder, and where results
are written.

## Tests

- The core: hand-checked positions, a hand-traced reference run, property tests over thousands of seeded runs, and
  one recorded run that pins the generator.
- Every strategy: one shared contract test (legal actions only, same seed gives the same result).
- The statistics: cases with a known answer.
- Strength or quality is measured in experiments, never asserted in unit tests.

## Growing into a full stack

This is a base stack: one overview skill. When a second project uses it, the repeated parts become a scaffold skill
and pattern skills (the binding's registry, the experiment runner, the worker protocol).
