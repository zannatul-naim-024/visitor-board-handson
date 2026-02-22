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
cd dummy-app
python3 -m venv .venv
source .venv/bin/activate   # Windows: .venv\Scripts\activate
pip install -r requirements.txt
```

**Each time you open a new terminal:** activate the venv, then run the app:

```bash
cd dummy-app
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

## Run locally against AWS

```bash
source .venv/bin/activate
export TABLE_NAME=workshop_messages
# Do not set DYNAMODB_ENDPOINT_URL — boto3 uses real AWS
python app.py
```

Open http://localhost:3000

---

## AWS setup (once)

1. **DynamoDB** — Table `workshop_messages`, partition key `id` (String).
2. **IAM** — EC2 instance profile (or env credentials): `dynamodb:PutItem`, `dynamodb:Scan`.

---

## Env vars

| Variable                  | Default             | Description |
|---------------------------|---------------------|-------------|
| `PORT`                    | 3000                | Server port |
| `TABLE_NAME`              | workshop_messages   | DynamoDB table |
| `AWS_REGION`              | us-east-1           | Region for DynamoDB |
| `DYNAMODB_ENDPOINT_URL`   | (none)              | Set to `http://localhost:8000` for DynamoDB Local |
