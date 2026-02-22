# Session 1: Single-Node System Design (Zero to Live)

**System design goal:** Define a **single-node** architecture with clear tiers (compute, network boundary, app, data) so we can scale the compute tier in Session 2 without changing the app or data layer.

**Prerequisites:** AWS account, browser, terminal, SSH client. Optional: domain for DNS.

---

## 0–10 min: Compute Tier — Why EC2 and Instance Type

### Design focus
- **Compute tier** = where the application runs. We choose EC2 to control OS, runtime, and to later clone this box (AMI).
- **Instance type** = capacity vs cost. t3.micro: 1 vCPU, 1 GB RAM — enough for the demo; we’ll scale by adding more instances, not by making this one huge.

### Steps (AWS Console)

1. **Region**  
   Pick one (e.g. `us-east-1`) and use it for the whole workshop.

2. **Launch instance**
   - **Name:** e.g. `workshop-web-01`
   - **AMI:** Ubuntu 22.04 LTS or Amazon Linux 2023
   - **Instance type:** **t3.micro** — *“Design choice: small unit of compute; scaling will be horizontal (more nodes), not vertical (bigger node).”*
   - **Key pair:** Create or select. *“Needed for SSH; part of the secure access design.”*
   - **Network:** Default VPC. We define the **network boundary** next.

3. **Storage**  
   Default (e.g. 8 GB gp3).

4. **Launch**  
   Note Instance ID; wait for **Running**. Keep the **.pem** path (e.g. `~/Downloads/workshop-key.pem`).

### Checkpoint
- Instance **Running**; key pair ready.
- **Design takeaway:** One compute node; we’ll add more in Session 2 using the same “shape” (AMI).

---

## 10–25 min: Network Boundary — Security Group as Perimeter

### Design focus
- **Security group** = explicit **network boundary**: who can reach this host and on which ports.
- **Least privilege:** SSH only from your IP; HTTP from the world. Avoid “0.0.0.0 on all ports” — that’s a design anti-pattern.

### Steps (AWS Console)

1. **EC2 → Security Groups**  
   Find the group attached to your instance (instance details → Security tab).

2. **Edit Inbound rules**
   - **SSH (22)** — Source: **My IP**. *“Only my IP can administer; reduces attack surface.”*
   - **HTTP (80)** — Source: **0.0.0.0/0**. *“App is public; we’ll add port 3000 or proxy to 80.”*

3. **Save**

### Checkpoint
- Inbound: 22 from your IP, 80 from 0.0.0.0/0. (Add 3000 if the app will listen on 3000.)
- **Design takeaway:** Perimeter is explicit; every open port is a deliberate design choice.

---

## 25–45 min: App Tier + Data Tier — Stateless App, State in DynamoDB

### Design focus
- **App tier:** Stateless process. Renders pages (SSR), handles requests; it does **not** store durable state on the instance.
- **Data tier:** DynamoDB (messages). All state lives here so that (1) we can replace the instance, (2) in Session 2 every new instance sees the same data.

### Before the session (one-time)
- Create DynamoDB table `workshop_messages`, partition key `id` (String).
- IAM: EC2 instance role (or env credentials) with DynamoDB (PutItem, Scan).

### Steps (terminal)

1. **SSH in**
   ```bash
   chmod 400 ~/path/to/your-key.pem
   ssh -i ~/path/to/your-key.pem ubuntu@<PUBLIC_IP>
   ```
   (Use `ec2-user` for Amazon Linux.)

2. **Deploy the app (Visitor Board)**
   ```bash
   sudo apt update
   sudo apt install -y python3 python3-pip python3-venv git
   git clone https://github.com/your-repo/aws-handson-01.git
   cd aws-handson-01/dummy-app
   python3 -m venv .venv && source .venv/bin/activate
   pip install -r requirements.txt
   export TABLE_NAME=workshop_messages
   export AWS_REGION=us-east-1
   python3 app.py &
   ```

3. **Verify**
   ```bash
   curl http://localhost:3000
   ```
   You should see the Visitor Board (SSR); “No messages yet” until you post.

4. **Security Group**  
   If the app listens on 3000: add **Inbound** Custom TCP **3000** from **0.0.0.0/0**. Or put Nginx in front and proxy to 3000 (then only 80 is public).

### Checkpoint
- App running; state (messages) is in DynamoDB, not on disk in the app directory.
- **Design takeaway:** App is stateless; data tier is shared. Adding more app instances later will not require moving state — they’ll use the same table.

---

## 45–60 min: Public Endpoint — Single IP (Later: Single DNS)

### Design focus
- **Single public endpoint** for the app. Today: instance **Public IP**. In Session 2 we’ll put an **ALB** in front so the endpoint stays stable when instances change.

### Steps

1. **Browser**  
   Open `http://<PUBLIC_IP>:3000` (or `http://<PUBLIC_IP>` if proxied). Post a message; refresh — data comes from DynamoDB. *“State is in the data tier; the box is just compute.”*

2. **Optional — DNS**  
   Create an **A record** (e.g. `workshop.yourdomain.com` → `<PUBLIC_IP>`). *“Design idea: one stable name. Next session we’ll point that name at the ALB instead of a single IP.”*

### Checkpoint
- App is public; state visible across refreshes (DynamoDB).
- **Design takeaway:** We have a working single-node design with clear compute / network / app / data tiers. Session 2 adds more compute nodes and a single entry point (ALB).

---

## Session 1 Summary (Design View)

| Phase | Time | Design concept | Outcome |
|-------|------|----------------|---------|
| Compute tier | 0–10 | EC2 as compute unit; instance type = capacity/cost | One node running |
| Network boundary | 10–25 | SG as explicit perimeter; least privilege | Ports 22, 80 (and 3000 if needed) |
| App + data tiers | 25–45 | Stateless app; state only in DynamoDB | Visitor Board live; state in managed services |
| Public endpoint | 45–60 | Single IP (and optional DNS) | Public URL; ready to put ALB in front in S2 |

**Next:** Session 2 — same app and data tier; we add ALB (single entry), AMI (immutable image), and ASG (elastic compute tier). See `SYSTEM-DESIGN.md` for the full architecture.
