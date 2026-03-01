# System Design — Architecture Overview

This document summarizes the **system we design** across both sessions and the **design decisions** behind it.

---

## End-state architecture (after Session 2)

```
                    [ Internet ]
                          |
                    [ ALB :80 ]
                    (single DNS)
                          |
         +----------------+----------------+
         |                |                |
    [ EC2 ]          [ EC2 ]          [ EC2 ]   ...  (ASG: min 1, max 10)
         |                |                |
         +----------------+----------------+
                          |
              +-----------+
              |
        [ DynamoDB ]
        (messages)
```

- **Clients** talk to one stable endpoint (ALB DNS). They never see instance IPs.
- **Compute tier:** Stateless app servers. Any instance can serve any request; no session state on the box.
- **Data tier:** DynamoDB (messages). Shared by all instances — this is why the app can scale horizontally.

---

## Session 1: Single-node design

**Goal:** One box that already follows the design we will scale.

| Component | Role in the design |
|-----------|--------------------|
| **EC2** | Compute tier — runs the app process. Instance type = capacity/cost tradeoff (t3.micro for demo). |
| **Security Group** | Network boundary — defines what can reach the host (SSH from you, HTTP from world). Explicit perimeter, not “open everything.” |
| **App (Visitor Board)** | Stateless request handler. Renders pages (SSR), reads/writes **only** DynamoDB. No local state that must survive restart or replicate. |
| **DynamoDB** | Shared state store for app data (messages). Decouples “where the request runs” from “where the data lives.” |

**Design decision:** Put all durable state in DynamoDB. The EC2 instance is disposable; we can replace it or clone it (AMI) without losing data.

---

## Session 2: Scaling the compute tier

**Goal:** More capacity by adding instances, without changing the data tier or the app.

| Component | Role in the design |
|-----------|--------------------|
| **Launch Template** | Base AMI + user data (install git, clone, run). Same script on every instance; no custom AMI needed. |
| **ALB** | Single entry point. Stable DNS, health checks, distributes traffic across healthy targets. Clients don’t care how many instances exist. |
| **Target group** | “Pool” of instances the ALB can send traffic to. ASG registers new instances here when it scales out. |
| **ASG** | Elastic compute tier: min/desired/max and a **scaling policy** (e.g. CPU > 50% → add capacity). Control loop: metric → decision → action. |

**Design decision:** Only the **compute tier** scales horizontally. Data tier (DynamoDB) is shared and scaled separately (DynamoDB capacity).

---

## Key design principles (to call out in sessions)

1. **Stateless app tier** — No session or app state on the instance. State lives in DynamoDB so any instance can serve any user.
2. **Single entry point** — ALB gives one DNS name. Backend topology (number of instances, which AZ) can change without client changes.
3. **Explicit network boundary** — Security groups define who can reach what. Reduces blast radius and clarifies the design.
4. **Reproducible compute** — Launch Template with user data (install git, clone, run). Same script on every new instance; no custom AMI needed.
5. **Scaling as a control loop** — Metric (e.g. CPU) → threshold (e.g. 50%) → action (add/remove instance). Design the policy, then observe it.

---

## Design vs implementation

| Concept | In the workshop |
|---------|------------------|
| Compute tier | EC2, then ASG |
| Network boundary | Security groups |
| Entry point | Public IP (S1), then ALB (S2) |
| App | Visitor Board (Flask, SSR) |
| Shared state | DynamoDB table |
| Elasticity | ASG min/desired/max + target-tracking policy; Launch Template user data for app bootstrap |

Use this as the reference when explaining *why* we do each step, not just *how*.
