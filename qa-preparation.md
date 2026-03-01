# Q&A — System Design Angles (~30 min)

After the two sessions, answers are framed as **system design** choices: tiers, tradeoffs, and scaling patterns.

---

## 1. Cost — "How much did that scaling just cost me?"

### Design framing
**Operational cost is a design constraint.** We designed for **scale-down** as well as scale-up: when load drops, the ASG reduces capacity so you pay for what you use.

### Points to make

- **Scale-in is part of the design:**  
  Target-tracking (e.g. CPU 50%) scales **in** when CPU falls. You don’t leave 10 instances running; you converge back toward min (e.g. 1). Cost follows capacity.

- **Guardrails:**  
  **ASG Max** (e.g. 10) is a design choice to cap runaway cost. **Budget alerts** in AWS Billing are another: define a cost boundary and get notified.

- **Rough numbers (illustrative):**  
  t3.micro ~\$0.01/hr; ALB ~\$0.02/hr + LCU. A 1–2 hour workshop is cents. Always check Billing.

- **Cleanup:**  
  Terminate ASG instances, delete the ALB, and optionally the AMI when done — design for “tear down” as well as “spin up.”

### One-liner
“We designed the system to scale down when load drops; ASG max and budgets are the cost guardrails.”

---

## 2. State — "With 10 servers, where does the user's session go?"

### Design framing
**Where state lives is a tier design decision.** Our app is **stateless** (no session in instance memory); durable state is in DynamoDB. Session state (e.g. login) is the same kind of decision: in-memory vs shared store.

### Points to make

- **The design problem:**  
  User hits Instance A (session in A’s memory). Next request goes to B (ALB round-robin). B has no session → user appears logged out. So **in-memory session state doesn’t fit a multi-instance design.**

- **Design options:**  
  1. **Sticky sessions (ALB):** Same user → same instance. Simple but couples user to instance; worse load distribution and no resilience if that instance dies.  
  2. **Shared session store:** Redis (ElastiCache) or a database. Every instance reads/writes the same store — **same pattern as our DynamoDB:** shared data tier.  
  3. **Stateless auth:** JWT (or similar) in a cookie; no server-side session. Any instance can validate the token.

- **What we did in the workshop:**  
  Visitor Board keeps **application state** (messages) in DynamoDB, not on the instance. Session state (login) is the same idea: put it in a shared tier (Redis/DB) or make it stateless (JWT).

### One-liner
“With multiple app instances, session state has to live in a shared tier (Redis/DB) or in the client (e.g. JWT). Keeping it only in instance memory is a design that doesn’t scale.”

---

## 3. Database — "Does the database scale the same way?"

### Design framing
**The data tier has different scaling patterns than the compute tier.** We scale the **app tier** horizontally (more identical instances). The **database tier** usually scales up (bigger instance) and/or out with read replicas; it’s a shared stateful service, not N identical stateless nodes.

### Points to make

- **Compute tier (what we built):**  
  Stateless app servers behind ALB. Scale out by adding instances; any instance can serve any request. **Horizontal scaling.**

- **Database tier:**  
  Typically one primary (or small cluster) holding durable state. You don’t “auto-scale to 50 database instances” like an ASG. You:
  - **Scale up:** Larger instance (more CPU/RAM).
  - **Scale out reads:** Add **read replicas**; writes go to primary (RDS, Aurora).
  - **Aurora:** Managed; storage auto-scales; add/remove read replicas for read scaling.

- **RDS / Aurora:**  
  Managed relational DB (no SQL in our app, but the question is about “database” in general). RDS: single primary + read replicas. Aurora: same idea with auto-scaling storage and replicas. Design takeaway: **data tier scaling is vertical + read replicas**, not “more and more identical writable nodes” like the app tier.

### One-liner
“App tier scales horizontally (ASG). Database tier scales up (bigger instance) and out for reads (replicas). Use RDS or Aurora so AWS manages that tier.”

---

## Quick reference — design framing

| Topic | Design angle |
|-------|----------------|
| **Cost** | Design for scale-down; ASG max and budgets as guardrails |
| **State** | Tier decision: state in shared store (Redis/DB) or stateless (JWT), not in instance memory |
| **Database** | Data tier scales up + read replicas; different pattern from horizontal app-tier scaling |

Use `SYSTEM-DESIGN.md` when you need to tie answers back to the overall architecture (compute vs data tier, stateless app, single entry point).
