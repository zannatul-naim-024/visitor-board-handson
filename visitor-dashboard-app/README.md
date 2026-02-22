# Visitor Board — System Design Demo App

**Role in the workshop:** Illustrates a **stateless app tier** and **shared data tier** (DynamoDB). No SQL; state lives only in the managed data tier so the compute tier can scale horizontally in Session 2.

- **App tier:** Flask, SSR. No durable state on the instance; every request reads/writes DynamoDB.
- **Data tier:** DynamoDB (messages). Shared by all instances — any box can serve any user.

See `../SYSTEM-DESIGN.md` for how this fits the full architecture.

---

## Virtual environment (required)

Use a venv so `pip` doesn’t touch the system Python (avoids “externally-managed-environment” on Homebrew Python).

**One-time setup (create venv and install deps):**

```bash
cd visitor-dashboard-app
python3 -m venv .venv
source .venv/bin/activate   # Windows: .venv\Scripts\activate
pip install -r requirements.txt
```

**Each time you open a new terminal:** activate the venv, then run the app:

```bash
cd visitor-dashboard-app
source .venv/bin/activate
# then run app (see below)
```

---

## Run with DynamoDB Local (Docker Compose)

No AWS account needed. Uses DynamoDB Local in Docker.

```bash
# Start DynamoDB Local
docker compose up -d

# Create the table (once)
source .venv/bin/activate
export DYNAMODB_ENDPOINT_URL=http://localhost:8000
python create_table.py

# Run the app (venv must be activated)
export DYNAMODB_ENDPOINT_URL=http://localhost:8000
export TABLE_NAME=workshop_messages
python app.py
```

Open http://localhost:3000.

---

## Run with AWS DynamoDB

Use the same app and the same table shape against **real AWS DynamoDB**.

### 1. Create the table in AWS

**Option A — AWS CLI** (same schema as local):

```bash
aws dynamodb create-table \
  --table-name workshop_messages \
  --attribute-definitions AttributeName=id,AttributeType=S \
  --key-schema AttributeName=id,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region eu-north-1
```

**Option B — Python script** (uses your default AWS credentials; do **not** set `DYNAMODB_ENDPOINT_URL`):

```bash
source .venv/bin/activate
export TABLE_NAME=workshop_messages
export AWS_REGION=eu-north-1
# Leave DYNAMODB_ENDPOINT_URL unset
python create_table.py
```

**Option C — Console:** AWS → DynamoDB → Create table → Name: `workshop_messages`, Partition key: `id` (String), Table settings: On-demand.

### 2. Credentials

- **Local:** Configure AWS CLI (`aws configure`) or set `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION` (or use a profile).
- **EC2:** Attach an IAM role to the instance with `dynamodb:PutItem`, `dynamodb:Scan` on that table.

### 3. Run the app

```bash
source .venv/bin/activate
export TABLE_NAME=workshop_messages
export AWS_REGION=eu-north-1
# Do not set DYNAMODB_ENDPOINT_URL — boto3 uses real AWS
python app.py
```

Open http://localhost:3000. Data is stored in AWS DynamoDB.

### Query AWS DynamoDB (CLI)

Same operations as local, but **omit** `--endpoint-url` so the CLI uses real AWS:

```bash
aws dynamodb list-tables --region eu-north-1
aws dynamodb scan --table-name workshop_messages --region eu-north-1
```

---

## AWS setup (once)

1. **DynamoDB** — Table `workshop_messages`, partition key `id` (String). Use CLI or console (see “Run with AWS DynamoDB” above).
2. **IAM** — For local: `aws configure` or env vars. For EC2: see **EC2: IAM instance profile** below.

### EC2: IAM instance profile (fix "Unable to locate credentials")

On EC2, boto3 gets credentials from the **instance profile** (IAM role attached to the instance). If you see `Unable to locate credentials`, attach a role that has DynamoDB access.

**1. Create an IAM policy** (e.g. name: `WorkshopVisitorBoardDynamoDB`):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:CreateTable",
        "dynamodb:DescribeTable",
        "dynamodb:PutItem",
        "dynamodb:Scan"
      ],
      "Resource": "arn:aws:dynamodb:eu-north-1:*:table/workshop_messages"
    }
  ]
}
```

(Region in the ARN is eu-north-1; or use `arn:aws:dynamodb:*:*:table/workshop_messages` for any region.)

**2. Create an IAM role** for EC2:

- **Trust policy:** allow `ec2.amazonaws.com` to assume the role.
- **Permissions:** attach the policy above.

**3. Attach the role to the instance:**

- **EC2 → Instances** → select the instance → **Actions** → **Security** → **Modify IAM role** → choose the role → **Update IAM role**.

**4. Retry on the instance** (no reboot needed):

```bash
export TABLE_NAME=workshop_messages
export AWS_REGION=eu-north-1
python create_table.py
python app.py
```

Credentials are provided automatically via instance metadata; no `aws configure` on the box.

---

## Env vars

| Variable                  | Default             | Description |
|---------------------------|---------------------|-------------|
| `PORT`                    | 3000                | Server port |
| `TABLE_NAME`              | workshop_messages   | DynamoDB table |
| `AWS_REGION`              | eu-north-1          | Region for DynamoDB |
| `DYNAMODB_ENDPOINT_URL`   | (none)              | Set to `http://localhost:8000` for DynamoDB Local |
