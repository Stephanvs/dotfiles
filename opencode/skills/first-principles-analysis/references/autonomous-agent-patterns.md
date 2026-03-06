# Autonomous Agent Patterns

Read this file when the task requires tool use, multi-step execution, or decisions that are costly to reverse.

## Agent loop

Use this loop:

1. Define the decision to be made or the outcome to produce.
2. Name the 1 to 3 load-bearing unknowns.
3. Decide which unknown is cheapest and most important to resolve first.
4. Gather targeted evidence.
5. Update the model.
6. Either act, gather the next piece of evidence, or stop because the remaining uncertainty no longer matters.

## What to gather first

Prefer evidence in this order:

1. Evidence that can eliminate an option entirely.
2. Evidence that reveals the true bottleneck.
3. Evidence that changes whether the action is safe or reversible.
4. Evidence that reduces minor tuning uncertainty.

## Preflight checks

Before taking consequential action, verify:

- scope: what exactly will change
- dependencies: what the action assumes is already true
- permissions: whether the agent is allowed to do it
- reversibility: how to undo it
- observability: how success or failure will be detected

## Good stopping conditions

Stop investigating when one of these becomes true:

- a clear option dominates on objective, constraints, and risk
- the next evidence step is unlikely to change the decision
- the remaining uncertainty can be handled with monitoring or rollback
- the task is actually routine and no deeper decomposition is useful

## Escalation conditions

Escalate or ask for confirmation when:

- the action is irreversible or hard to reverse
- the task touches legal, financial, security, or safety-critical constraints
- the evidence base is too weak for a responsible recommendation
- two options have materially different value systems or stakeholder tradeoffs

## Cheap tests to prefer

When possible, choose:

- a dry run over a live change
- a sample over the full dataset
- a read-only inspection over a write operation
- a local reproduction over a production experiment
- a reversible pilot over a full rollout

## Reporting discipline

When you report back, separate:

- observed facts
- inferred mechanism
- assumptions still in play
- recommendation
- immediate next step

That separation matters. It prevents the agent from presenting a neat story that hides weak evidence.
