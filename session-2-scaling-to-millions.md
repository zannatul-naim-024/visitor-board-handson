# Session 2: Evolving to a Scalable System Design

**System design goal:** Evolve the single-node design into a **scalable** one: **single entry point** (ALB), **elastic compute tier** (ASG). The app and data tier stay the same; only the compute tier scales. We use **user data** to install git, clone the repo, and start the app on each instance — no AMI needed.

**Prerequisites:** Session 1 done. EC2 instance with Visitor Board running; DynamoDB in use. IAM instance profile for EC2 with DynamoDB access (same as Session 1).

**Architecture diagram:** See [session-2-architecture.excalidraw.json](session-2-architecture.excalidraw.json) (open in Excalidraw) or [session-2-architecture.mmd](session-2-architecture.mmd) (Mermaid).

---

## 0–25 min: Single Entry Point — ALB and Stable DNS

### Design focus
- **ALB** = single entry point for clients. One DNS name; clients don’t know how many instances exist or their IPs.
- **Target group** = pool of instances the ALB routes to. Health checks decide which targets get traffic.
- **Design principle:** Decouple “client endpoint” from “backend topology.” We can add/remove instances without changing the client.

### Steps (AWS Console)

1. **EC2 → Load Balancers → Create**
   - **Type:** Application Load Balancer
   - **Name:** `workshop-alb`
   - **Scheme:** Internet-facing, **IP:** IPv4

2. **Network**
   - **VPC:** Default. **Mappings:** At least two AZs (e.g. us-east-1a, us-east-1b).

3. **Security group**
   - New or existing. **Inbound:** HTTP 80 from **0.0.0.0/0**. *“Traffic hits the ALB first; ALB forwards to instances.”*

4. **Target group**
   - Create **new** target group: `workshop-tg`
   - **Target type:** Instances. **Protocol:** HTTP, **Port:** 3000 (or 80 if app is proxied)
   - **VPC:** Same as ALB. **Health check:** Path `/` or `/health`. Create.

5. **Register current instance (optional)**  
   In the target group, **Register** the Session 1 instance so the ALB has a healthy target. Wait until **Healthy**.

6. **ALB listener**
   - ALB → **Listeners** → Add listener: **HTTP :80** → Forward to `workshop-tg`. Save.

7. **Test**  
   Open the ALB **DNS name** in the browser. You should see the Visitor Board. *“This URL is stable. Behind it we’ll add or remove instances; the design is ‘one entry point, N app servers.’”*

### Checkpoint
- ALB **Active**; listener 80 → target group; at least one **Healthy** target.
- **Design takeaway:** Clients use one endpoint; the compute tier can scale behind it.

---

## 25–50 min: Elastic Compute Tier — ASG and Scaling Policy

### Design focus
- **ASG** = the **elastic compute tier**: min/desired/max and a **scaling policy** (e.g. CPU > 50% → add instance).
- **Launch Template** = “how to start one instance”: base AMI + **user data** that installs git, clones the repo, and starts the app. Same script on every node — no AMI creation step.
- **Design principle:** Scaling is a **control loop**: metric → threshold → action. We design the policy; AWS runs the loop.

### Steps (AWS Console)

1. **Launch Template**
   - **EC2 → Launch Templates → Create**
   - **Name:** `workshop-launch-template`
   - **AMI:** Amazon Linux 2023 (or same base AMI as Session 1). **Instance type:** t3.micro. **Key pair:** Same as Session 1. **Network:** Default VPC, public IP. **Security group:** Same as Session 1 (22 + 80/3000).
   - **IAM instance profile:** Same as Session 1 (role with DynamoDB access).
   - **Advanced details → User data:** paste the script below. Each new instance will install git, clone the repo, set up the app, and start it (takes a few minutes to become healthy):
   ```bash
   #!/bin/bash
   set -e
   dnf install -y python3 python3-pip git
   cd /root
   git clone https://github.com/zannatul-naim-024/visitor-board-handson.git
   cd visitor-board-handson/visitor-dashboard-app
   python3 -m venv .venv && source .venv/bin/activate
   pip install -r requirements.txt
   TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
   export INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" "http://169.254.169.254/latest/meta-data/instance-id")
   export TABLE_NAME=workshop_messages
   export AWS_REGION=eu-north-1
   nohup python3 app.py > /var/log/visitor-app.log 2>&1 &
   ```
   - Create template.

2. **Auto Scaling Group**
   - **EC2 → Auto Scaling Groups → Create**
   - **Name:** `workshop-asg`
   - **Launch template:** `workshop-launch-template`
   - **VPC:** Default. Select subnets in **at least 2 AZs**.

3. **Group size (design levers)**
   - **Desired:** 2, **Minimum:** 1, **Maximum:** 10  
   - *“Design: we cap at 10 to control cost; minimum 1 for availability; desired 2 for a bit of spread.”*

4. **Attach to ALB**
   - **Attach to load balancer:** Yes. **Target group:** `workshop-tg`.
   - **Health check grace period:** 300 seconds (or more). *Instances need a few minutes for user data to install git, clone, and start the app before they can pass the health check.*
   - *“New instances register to the same pool; ALB sends them traffic.”*

5. **Scaling policy**
   - **Add scaling policy** → **Target tracking**
   - **Metric:** CPU utilization. **Target:** 50%.  
   - *“Design: when CPU goes above 50%, add capacity; when it drops, remove. This is the control loop we’ll observe.”*

6. **Create ASG**  
   Wait until 2 instances are **InService** and **Healthy** in the target group.

### Checkpoint
- ASG has 2 instances; both in target group; ALB still serves the app.
- **Design takeaway:** Compute tier is elastic; data tier (DynamoDB) is unchanged and shared by all instances.

---

## 50–60 min: Observe the Control Loop — Custom Scripts Show Scaling

### Design focus
- **Observe the design in action:** Metric (CPU) exceeds threshold → policy fires → ASG adds an instance. No manual launch.
- **Custom scripts** in this repo show scaling in the terminal: which instance serves each request, and (optionally) ASG capacity over time.
- **Visitor Board** stays consistent because state is in DynamoDB; any instance can serve any request.

### Custom scripts (see scaling in action)

Scripts live in **`session-2-scripts/`**. See `session-2-scripts/README.md` for full usage.

1. **Show which instance serves each request** (run in Terminal 1; keep running):
   ```bash
   chmod +x session-2-scripts/show_scaling.sh
   ./session-2-scripts/show_scaling.sh http://YOUR_ALB_DNS 1
   ```
   Output: `14:32:01  Instance: i-0abc123...`. When the ASG scales out, **new instance IDs appear** — that’s scaling in action.

2. **Generate load** (run in Terminal 2) to help push CPU up and trigger scale-out:
   ```bash
   chmod +x session-2-scripts/generate_load.sh
   ./session-2-scripts/generate_load.sh http://YOUR_ALB_DNS 120 8
   ```
   Sends concurrent requests for 2 minutes. For stronger CPU spike, also stress one instance (step 3 below).

3. **Optional — watch ASG capacity in the terminal** (Terminal 3):
   ```bash
   chmod +x session-2-scripts/watch_asg.sh
   ./session-2-scripts/watch_asg.sh workshop-asg 5
   ```
   Prints desired/min/max and instance IDs every 5 seconds. You’ll see desired capacity and instance count change when the policy runs.

### Steps (stress CPU to trigger scale-out)

1. **SSH into one ASG instance**  
   `ssh -i your-key.pem ec2-user@<INSTANCE_IP>` (Amazon Linux). Or use Session 1 instance if it’s still in the target group.

2. **Raise CPU** so target-tracking (50%) fires:
   ```bash
   sudo dnf install -y stress-ng
   stress-ng --cpu 2 --timeout 300
   ```
   (Amazon Linux: `dnf`; on Ubuntu use `apt` and `apt install stress-ng`.)

3. **Watch the system**
   - **Terminal 1:** `show_scaling.sh` will start showing a **new** instance ID once the ASG adds a node and it becomes healthy.
   - **EC2 → Auto Scaling Groups → workshop-asg:** **Activity** tab → “Incrementing desired capacity”; **Instances** tab → 3rd instance **InService**.
   - *“The control loop we designed: metric → policy → action. The scripts make it visible in the terminal.”*

4. **Optional**
   - Open the ALB URL in a browser and refresh; the “Served by” line may change (round-robin). Same data (DynamoDB) — **stateless app + shared data tier** in action.

### Checkpoint
- CPU spike → ASG adds instance; custom scripts show which instance serves and (optionally) ASG capacity. Design is observable.
- **Design takeaway:** Elastic compute tier responds to load; app and data design (stateless + DynamoDB) make this safe.

---

## Session 2 Summary (Design View)

| Phase | Time | Design concept | Outcome |
|-------|------|----------------|---------|
| Single entry point | 0–25 | ALB = stable DNS; target group = pool | One URL, N instances behind it |
| Elastic compute tier | 25–50 | Launch Template + user data (install git, clone, run); ASG + policy = control loop | Min 1, desired 2, max 10; scale on CPU |
| Observe the loop | 50–60 | Custom scripts + stress → metric → scale-out | New instance appears; scripts show which instance serves |

**Next:** Q&A — cost, state, and database from a system-design perspective. See `qa-preparation.md` and `SYSTEM-DESIGN.md`.
