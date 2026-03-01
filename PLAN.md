# AWS Hands-On: System Design Focus — Master Plan

**Total runtime:** 2 × 60 min (Session 1 + Session 2) + 30 min Q&A  
**Focus:** System design — architecture, components, tradeoffs. Console work illustrates the design.

---

## Design narrative

We build and then **evolve** one system:

- **Session 1:** Design a **single-node** system: compute boundary, network boundary, application tier, and **shared state store** (DynamoDB). No state on the box — so the same design can scale in Session 2.
- **Session 2:** Evolve to a **scalable** design: **single entry point** (ALB), **elastic compute tier** (ASG). Same data layer; new instances use user data (install git, clone, run) — no AMI step.

Every step is tied to a **design decision** or **tradeoff**, not just “click here.”

---

## Overview

| Session | Design goal | Outcome |
|--------|-------------|---------|
| **Session 1** | Single-node architecture | Compute (EC2), network (SG), app tier, shared state (DynamoDB) — designed so we can scale out later |
| **Session 2** | Scalable multi-node architecture | LB as single entry, ASG as elastic tier, scaling policy; observe the control loop |
| **Q&A** | Design tradeoffs | Cost, stateful tiers, database scaling — explained as system design choices |

---

## Session 1: Single-Node System Design (60 min)

| Block | Time | Design focus | What you do |
|-------|------|--------------|-------------|
| **Compute tier** | 0–10 min | Why EC2; instance type as capacity/cost tradeoff | Launch EC2 (t3.micro), key pair |
| **Network boundary** | 10–25 min | Security group as explicit perimeter; least privilege | SG: SSH (your IP), HTTP (world) |
| **App + data tiers** | 25–45 min | Stateless app process; state in DynamoDB only | Deploy Visitor Board (Flask), connect to DynamoDB |
| **Public endpoint** | 45–60 min | Single public IP; optional DNS (IP → URL) | Browser to IP; optional A record |

**Design takeaway:** Clear separation — compute runs the app, data lives in managed services. That makes the next step (more compute nodes) a design change, not an app rewrite.

---

## Session 2: Evolving to a Scalable Design (60 min)

| Block | Time | Design focus | What you do |
|-------|------|--------------|-------------|
| **Single entry point** | 0–25 min | Stable DNS; clients don't depend on instance list | Create ALB, target group, listener |
| **Elastic compute tier** | 25–50 min | Launch Template (base AMI + user data); ASG + scaling policy | Launch Template + ASG, attach to ALB |
| **Observe the loop** | 50–60 min | Metric → policy → action; custom scripts show scaling | Stress CPU / generate load; watch ASG add instance |

**Design takeaway:** App tier is stateless and horizontally scalable; shared state stays in DynamoDB. Scaling is a control-loop design (metric, threshold, action).

---

## Q&A — System design angles (30 min)

| Topic | Design framing |
|-------|----------------|
| **Cost** | Design for scale-down; ASG max as guardrail; budgets as operational constraint |
| **State** | Where state lives (app memory vs shared store) is a tier design decision |
| **Database** | Data tier scales differently (scale-up, read replicas); RDS/Aurora as managed option |

---

## File map

- **`PLAN.md`** (this file) — Master plan, design narrative, time blocks
- **`SYSTEM-DESIGN.md`** — Architecture overview and design decisions (reference for both sessions)
- **`session-1-zero-to-live.md`** — Session 1: design-focused runbook (single-node system)
- **`session-2-scaling-to-millions.md`** — Session 2: design-focused runbook (scalable evolution)
- **`qa-preparation.md`** — Q&A with system-design answers
- **`visitor-dashboard-app/`** — Stateful demo app (DynamoDB) used to illustrate the design

Use the session MDs as runbooks; use PLAN.md and SYSTEM-DESIGN.md for the “why” and architecture.
