---
name: software-architect
description: Design and build software with high cohesion, low coupling, composition-first structures, and functional-style defaults (TigerStyle-inspired).
license: MIT
allowed-tools:
  - read
  - write
  - edit
  - grep
  - glob
  - list
  - bash
  - webfetch
metadata:
  version: "1.0"
---

# Software Architect

> “Make things as simple as possible, but no simpler.” — Albert Einstein

This skill is for architecting and implementing software that is:

- Highly cohesive (each module has a clear purpose).
- Loosely coupled (modules depend on stable interfaces, not internal details).
- Composition-first (prefer wiring small parts together over inheritance trees).
- Functional-style by default (pure core, explicit effects, data-oriented design).
- Disciplined about quality (simplicity over cleverness; high standards).

TigerStyle-inspired ideas are used as *defaults* and *heuristics* (apply when they improve safety,
correctness, clarity, or performance; relax when they add accidental complexity).

## North Star

- Optimize for **correctness through understanding**, then performance.
- Prefer **simple, explicit control flow** over implicit behavior.
- Choose the **smallest design that fully solves the problem**.
- Treat “clever” as a code smell; prefer boring, obvious solutions.
- Pay down confusion immediately (rename, simplify, split, delete).

## Architecture Goals

### High Cohesion

- Each module has exactly one job and one reason to change.
- Keep related data and the code that manipulates it together (ownership is a design tool).
- Create APIs that reflect the domain (nouns/verbs that fit), not the implementation.

### Low Coupling

- Depend on **interfaces/ports** and data contracts, not concrete implementations.
- Make dependencies explicit at construction time (dependency injection over hidden globals).
- Keep the public surface area small and stable; keep internals private and replaceable.
- Avoid “action at a distance” (side effects and shared mutable state that surprise callers).

### Composition Over Inheritance / Dynamic Polymorphism

Use inheritance and deep OO polymorphism only when it is clearly the simplest tool.
Default to:

- Composition: build behavior by wiring small components together.
- Parameterization: pass functions/strategies/config instead of subclassing.
- Data + functions: plain data structures and pure transformations.
- Sum types / tagged unions + pattern matching (when available) instead of subtype webs.
- Small interfaces (ports) that describe capabilities, not “class identity”.

**Rule of thumb:** prefer “*assemble* behavior at the boundary” over “*embed* behavior in types”.

## Functional-Style Defaults

### Functional Core, Imperative Shell

- Put domain logic in **pure functions** (deterministic, testable, no I/O).
- Keep I/O, time, randomness, and external services in the **imperative shell**.
- Make boundaries explicit: parsing/validation, domain decisions, side effects.

Pseudo-structure:

```text
imperative shell:
  load inputs (I/O)
  validate/parse -> domain types
  call pure domain functions
  persist/emit effects (I/O)
```

### Immutability and Data Flow

- Prefer immutable data and persistent transformations.
- Minimize mutable state; if state must exist, confine it (single owner, clear lifecycle).
- Prefer returning new values over mutating shared ones.
- Avoid hidden mutation via global caches/singletons (unless carefully isolated and justified).

### Errors as Values

- Model failures explicitly (Result/Either/Option) instead of implicit exceptions where possible.
- Separate **programmer errors** (bugs, invalid invariants) from **operational errors** (timeouts,
  disk full, network failures).
- Fail fast on programmer errors (assert/throw/panic) and handle operational errors deliberately.

## TigerStyle-Inspired Defaults (Apply When Applicable)

These are high-leverage defaults for quality and safety. Apply them when they reduce risk and
improve clarity; relax them when the surrounding ecosystem makes them counterproductive.

### Prefer Explicitness

- Avoid magic, reflection-heavy control flow, and spooky metaprogramming.
- Prefer iteration over recursion; use recursion only when clearly bounded and simpler.
- Make non-obvious defaults explicit at call sites (especially for safety/performance knobs).
- Keep control flow in one place (“push `if`s up and `for`s down”):
  - Parent functions own branching and orchestration.
  - Leaf helpers do straight-line work and stay pure.

### Put Limits on Everything

- Ensure loops/queues/retries have clear upper bounds and timeouts.
- Bound work per request/event to avoid tail-latency spikes.
- Avoid unbounded memory growth (caches need eviction and explicit sizing).

### Assert and Enforce Invariants

- Use assertions/contracts to encode invariants at boundaries (inputs, outputs, state transitions).
- When an invariant is critical, assert it in *two* places (before crossing a boundary and after
  crossing it) when practical.
- Prefer multiple small assertions over one compound assertion (easier to debug and reason about).

### Design First, Then Build

- Spend thought upfront: define invariants, data model, interfaces, failure modes.
- Do performance “back-of-the-envelope” sketches early (big-O and resource costs).
- Avoid premature abstraction; but also avoid “we’ll fix it later” debt.

### Zero-Technical-Debt Attitude

- Do not ship known footguns (missing error handling, unbounded loops, fragile concurrency,
  unclear ownership, undocumented invariants).
- If you must compromise, make it explicit: capture the rationale and a concrete follow-up.

## How to Design (Before Writing Code)

1. **Clarify the problem**
   - What are the inputs/outputs?
   - What must always be true (invariants)?
   - What are the failure modes and recovery expectations?

2. **Choose boundaries and dependencies**
   - Identify the pure domain core.
   - Identify external systems (DB, network, filesystem, clock, random, UI).
   - Define ports/interfaces for external dependencies.

3. **Model the domain**
   - Use types and naming to prevent invalid states.
   - Prefer explicit units/qualifiers in names (`timeout_ms`, `limit_items_max`).

4. **Plan for testability**
   - Pure functions get unit tests.
   - Adapters get integration tests.
   - Edge cases include invalid/negative tests, not only happy paths.

## Implementation Guidelines

- Keep functions small enough to fit on a screen; split by responsibility.
- Keep mutable state tightly scoped; prefer local variables over shared fields.
- Keep APIs narrow: fewer parameters, simpler return types, fewer states.
- Prefer readable naming over abbreviations; choose nouns/verbs carefully.
- Delete dead code and unnecessary indirection.

## Checklists

### Architecture Checklist

- [ ] Clear module boundaries and ownership
- [ ] High cohesion within modules (no “misc” grab bags)
- [ ] Low coupling across modules (interfaces/ports, no internal leaks)
- [ ] Composition-first design (no unnecessary inheritance or frameworks-as-architecture)
- [ ] Pure core identified; effects isolated at boundaries
- [ ] Explicit error model and failure handling strategy
- [ ] Work/memory bounded where relevant
- [ ] Performance sketch done for hot paths

### Implementation Checklist

- [ ] Core logic is testable without I/O
- [ ] Side effects are explicit and centralized
- [ ] Invariants asserted at boundaries
- [ ] Error cases handled (not silently ignored)
- [ ] Naming is precise; no misleading abstractions
- [ ] Complexity reduced (simplify after it works)
- [ ] Docs/comments explain *why* for non-obvious decisions

### Review / Simplification Checklist

- [ ] Can a new engineer explain the design in 5 minutes?
- [ ] Are there fewer concepts than necessary? If yes, delete/merge.
- [ ] Are there more concepts than necessary? If yes, simplify.
- [ ] Does each module have one reason to change?
- [ ] Are dependencies pointing the right way (domain does not depend on infrastructure)?
- [ ] Are there hidden side effects or shared mutable state?
- [ ] Is any abstraction “clever”? Replace with something obvious.

## Examples (Language-Agnostic)

### Composition via Dependency Injection (no inheritance)

```text
def process_order(deps, command):
  validated = validate(command)
  decision  = decide(validated)         # pure
  effects   = plan_effects(decision)    # pure
  deps.outbox.publish(effects.events)   # I/O
  deps.repo.save(effects.state)         # I/O
```

`deps` is explicit (repo/outbox/clock/etc.), domain decisions stay pure, and behavior is composed by
passing dependencies rather than subclassing.

### Functional Core / Imperative Shell Boundary

```text
shell:
  raw_input -> parse/validate -> domain types
  domain types -> pure transform -> new domain types
  new domain types -> serialize/persist/emit
```

If you keep this boundary crisp, the system stays cohesive, low-coupled, and easy to test.
