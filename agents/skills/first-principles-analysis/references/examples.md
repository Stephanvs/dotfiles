# Extended Examples

## Example 1: Reduce cloud spend without harming reliability

### Weak framing
"Find cost-cutting best practices."

### First-principles framing
Objective: lower spend while preserving service quality.

Primitives:

- workload demand by time and service
- latency and availability requirements
- unit cost by compute, storage, and network
- idle capacity
- scaling lag
- error budget

Mechanism:
Costs rise because provisioned resources, data transfer, and replication policies do not match real demand or required reliability.

Better options often include:

- removing idle baseline capacity where demand is bursty
- changing data movement patterns before changing instance families
- matching reliability targets to actual service criticality
- separating hot paths from non-critical background work

## Example 2: Improve conversion on a signup flow

### Weak framing
"Copy what top SaaS companies do."

### First-principles framing
Objective: increase completed signups.

Primitives:

- user intent strength
- number of required actions
- friction per step
- trust signals
- page speed
- distraction
- error recovery

Mechanism:
Conversion falls when friction, confusion, or perceived risk rises faster than the user’s motivation.

This often leads to better questions:

- Which step loses the most motivated users?
- Which field or choice adds friction without materially improving downstream outcomes?
- Is the real issue qualification policy rather than page design?

## Example 3: Decide whether to build or buy internal software

### Weak framing
"Should we build this ourselves?"

### First-principles framing
Objective: achieve required capability at acceptable cost, speed, and control.

Primitives:

- capability gap
- uniqueness of requirements
- integration complexity
- switching cost
- security constraints
- internal maintenance burden
- vendor dependency risk
- time to value

Mechanism:
A build decision makes sense when unique requirements and control needs outweigh maintenance cost and slower delivery. A buy decision makes sense when the problem is commoditized and integration is tractable.

The key is not "what do smart companies do?" The key is which option best fits the underlying cost structure and constraint profile.
