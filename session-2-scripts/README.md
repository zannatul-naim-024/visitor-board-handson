# Session 2 — Scripts to Show Scaling

These scripts let you **see** EC2 Auto Scaling in action during the workshop.

| Script | Purpose |
|--------|--------|
| **show_scaling.sh** | Hit the ALB in a loop and print which instance served each request. When the ASG scales out, new instance IDs appear in the output. |
| **generate_load.sh** | Send sustained HTTP load to the ALB (and optionally raise CPU on instances). Use with target-tracking scaling to trigger scale-out. |
| **watch_asg.sh** | Poll the ASG via AWS CLI and print desired/min/max capacity and instance list. See the count change as the policy runs. |

---

## Prerequisites

- **show_scaling.sh** — `curl` (no AWS credentials).
- **generate_load.sh** — `curl` (no AWS credentials).
- **watch_asg.sh** — AWS CLI configured with permissions for `autoscaling:DescribeAutoScalingGroups`.

Optional: `jq` for cleaner output in `watch_asg.sh`.

---

## Quick demo (see scaling)

1. **Terminal 1 — watch which instance serves:**
   ```bash
   chmod +x session-2-scripts/show_scaling.sh
   export ALB_URL=http://your-alb-dns.elb.amazonaws.com
   ./session-2-scripts/show_scaling.sh 1
   ```
   You’ll see lines like `14:32:01  Instance: i-0abc123...`. Keep this running.

2. **Terminal 2 — generate load** (and/or SSH to an instance and run `stress-ng --cpu 2 --timeout 300`):
   ```bash
   chmod +x session-2-scripts/generate_load.sh
   ./session-2-scripts/generate_load.sh 120 8
   ```

3. **Terminal 3 (optional) — watch ASG capacity:**
   ```bash
   chmod +x session-2-scripts/watch_asg.sh
   ./session-2-scripts/watch_asg.sh workshop-asg 5
   ```

As the ASG scales out, Terminal 1 will start showing **new** instance IDs, and Terminal 3 will show higher desired capacity and more instance IDs. That’s the scaling loop in action.

---

## Environment / placeholders

- **ALB_URL** — Set to your ALB base URL (e.g. `export ALB_URL=http://workshop-alb-1640305800.eu-north-1.elb.amazonaws.com`). Scripts use this if set; otherwise pass the URL as the first argument.
- **workshop-asg** — Your Auto Scaling group name (for `watch_asg.sh`).
