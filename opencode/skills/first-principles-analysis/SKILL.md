---
name: first-principles-analysis
description: Decomposes complex problems into objective, constraints, assumptions, primitives, and causal mechanisms, then rebuilds solutions from the fundamentals. Use when solving ambiguous problems, debugging root causes, planning systems, evaluating tradeoffs, or when the user asks for first-principles thinking, fundamentals, a clean-slate design, or a deeper explanation than surface best practices.
---

# First Principles Analysis

Use this skill to reason from fundamentals instead of copying default patterns, received wisdom, or the most familiar analogy.

For tool-heavy work, open-ended agent execution, or irreversible actions, read [references/autonomous-agent-patterns.md](references/autonomous-agent-patterns.md).
For additional examples of the method in practice, read [references/examples.md](references/examples.md).

## When to use this skill

Apply this skill when the task has one or more of these characteristics:

- The problem is ambiguous, novel, or under-specified.
- Conventional solutions may hide bad assumptions.
- The user wants root-cause analysis rather than symptom treatment.
- The task involves system design, strategy, prioritization, pricing, process redesign, or deep debugging.
- There are conflicting objectives or non-obvious tradeoffs.
- The agent needs to decide what evidence matters before acting.

Do not force this skill onto trivial lookups, routine formatting, or tasks with a well-established procedure that already fits the goal.

## Core stance

- Separate facts from assumptions.
- Separate hard constraints from soft preferences.
- Prefer mechanisms over analogies.
- Rebuild from primitives rather than inherited templates.
- Keep uncertainty visible instead of pretending confidence.
- Preserve useful priors when they survive scrutiny. First-principles thinking means testing assumptions, not ignoring history.

## Operating procedure

### 1) Define the target clearly

State:

- the objective
- the success criteria
- the decision horizon
- the relevant stakeholder or system boundary

If important information is missing, either gather it or make the minimum explicit assumptions needed to proceed.

### 2) Extract constraints and assumptions

List and classify:

- hard constraints: physics, budget caps, laws, fixed interfaces, deadlines that are truly fixed
- soft constraints: preferences, conventions, habits, defaults, internal norms
- unknowns: facts that could materially change the answer
- inherited assumptions: "this is how people usually do it" beliefs that may not be fundamental

Flag which assumptions are load-bearing and need verification.

### 3) Decompose the problem into primitives

Identify the smallest useful building blocks for this task, such as:

- actors
- resources
- incentives
- information flows
- decision variables
- bottlenecks
- invariants
- causal dependencies

Keep decomposing until the next split no longer changes the solution.

### 4) Build a causal model

Explain what actually drives outcomes.

Look for:

- direct causes versus symptoms
- feedback loops
- thresholds and nonlinearities
- coordination costs
- failure points
- time delays
- second-order effects

When relevant, explicitly say what would have to be true for the current mental model to be wrong.

### 5) Re-derive options from the primitives

Generate a small set of options grounded in the causal model.

Aim for 2 to 4 serious alternatives, not one default plus filler. Favor options that:

- remove a false constraint
- redesign the system boundary
- attack the bottleneck directly
- simplify the number of moving parts
- improve reversibility or learning speed

Do not rank options by familiarity. Rank them by fit to the objective, constraints, and mechanism.

### 6) Stress test the options

For each serious option, check:

- best case and failure case
- operational complexity
- reversibility
- required coordination
- risk concentration
- hidden dependencies
- edge cases
- what evidence would falsify it quickly

If one option dominates only under a fragile assumption, say so.

### 7) Recommend and translate into action

Choose the highest-leverage option and explain:

- why it wins from first principles
- what tradeoffs were accepted
- what remains uncertain
- what to do next
- what to measure after execution

If no option is clearly superior, recommend the best next experiment instead of pretending a final answer exists.

## Default output structure

Use this structure when it helps. Compress or adapt it when the task is small.

```markdown
## Objective

## Constraints

## Assumptions to verify

## Primitives

## Causal model

## Options considered

## Recommended approach

## Risks and validation checks

## Next actions
```

## Quality bar

A good response produced with this skill should:

- expose hidden assumptions
- make the primitives legible
- explain the mechanism, not just the conclusion
- compare real alternatives
- identify what would change the answer
- end with an actionable recommendation or experiment

## Failure patterns to avoid

Avoid these common mistakes:

- repeating industry clichés as if they were primitives
- treating preferences as hard constraints without checking
- confusing symptoms with root causes
- overfitting to the first plausible explanation
- producing only one option and calling it objective
- hiding uncertainty or unresolved dependencies
- over-decomposing a simple task where direct execution is better

## Special instructions for autonomous agents

When acting autonomously:

1. Before using tools, identify the specific fact or constraint that most affects the decision.
2. Gather only evidence that can change the recommendation or action plan.
3. Prefer cheap tests of load-bearing assumptions over broad exploratory work.
4. Update the causal model when new evidence appears. Do not force new facts into the old story.
5. For destructive, high-cost, or irreversible actions, define a preflight check and rollback condition before execution.
6. If the environment is noisy or uncertain, favor reversible experiments and information gain.
7. If a standard pattern clearly dominates after analysis, say so plainly and stop decomposing.

## Mini examples

### Example: product strategy

Instead of asking, "Which feature do competitors have?", reduce the problem to user job, switching cost, frequency, willingness to pay, and distribution leverage. Then compare options by which primitive they improve most.

### Example: technical debugging

Instead of starting with a familiar fix, reduce the issue to inputs, state transitions, timing, resource limits, and external dependencies. Then test the smallest hypothesis that could explain the observed failure.

### Example: process redesign

Instead of copying another team’s workflow, reduce the process to queueing, handoffs, information quality, incentives, and approval latency. Then redesign around the actual bottleneck.
