# AWS Hands-On: System Design Focus

A **system design–focused** workshop: build a single-node system (EC2, Security Group, app + DynamoDB). Console work illustrates architecture, components, and tradeoffs.

**Region used in docs:** `eu-north-1` (change env/ARNs if you use another).

---

## What’s in this repo

| Document | Purpose |
|----------|---------|
| **[PLAN.md](PLAN.md)** | Master plan: design narrative, time blocks, session goals |
| **[SYSTEM-DESIGN.md](SYSTEM-DESIGN.md)** | Architecture overview and design decisions |
| **[aws-components-build-order](aws-components-build-order.excalidraw.json)** | Diagram: AWS components we create, one by one (S1 + S2). [Mermaid](aws-components-build-order.mmd) |
| **[session-1-zero-to-live.md](session-1-zero-to-live.md)** | Runbook: single-node system (EC2, SG, app + DynamoDB) — Amazon Linux |
| **[session-2-scaling-to-millions.md](session-2-scaling-to-millions.md)** | Runbook: EC2 auto scaling (AMI, ALB, ASG), plus custom scripts to show scaling |
| **[session-2-scripts/](session-2-scripts/)** | Scripts to watch which instance serves requests and to generate load / watch ASG |
| **[qa-preparation.md](qa-preparation.md)** | Q&A: cost, state, database — system design angles |
| **[visitor-dashboard-app/](visitor-dashboard-app/)** | Demo app (Flask, DynamoDB). See [visitor-dashboard-app/README.md](visitor-dashboard-app/README.md) to run locally or on EC2 |

---

## Quick start

- **Run the app locally (DynamoDB Local):**  
  See [visitor-dashboard-app/README.md](visitor-dashboard-app/README.md) → “Run with DynamoDB Local”.
- **Deliver Session 1:**  
  Use [session-1-zero-to-live.md](session-1-zero-to-live.md) as the runbook (Amazon Linux, eu-north-1).

---

## Session overview

| Session | Goal | Outcome |
|---------|------|---------|
| **1** | Single-node system design | EC2 + Security Group + Visitor Board (DynamoDB); public endpoint |
| **2** | Scalable compute tier | AMI, ALB, ASG; custom scripts show scaling (which instance serves, load, ASG capacity) |
