"""
Visitor Board — system design demo app.

Design: Stateless app tier + shared data tier (DynamoDB). No SQL.
- App tier: request/response only; no durable state on the instance.
- Data tier: all state in DynamoDB (messages) so any instance can serve any user.
See SYSTEM-DESIGN.md in the repo root.
"""
import os
import uuid
from flask import Flask, request, redirect, render_template_string
import boto3

app = Flask(__name__)

# Config: same env vars for AWS or local (DynamoDB Local via DYNAMODB_ENDPOINT_URL)
TABLE = os.environ.get("TABLE_NAME", "workshop_messages")
REGION = os.environ.get("AWS_REGION", "us-east-1")
INSTANCE_ID = os.environ.get("INSTANCE_ID", os.uname().nodename)
DYNAMODB_ENDPOINT = os.environ.get("DYNAMODB_ENDPOINT_URL")  # e.g. http://localhost:8000 for local

# Data tier — shared by all app instances (design: single source of truth off-instance)
dynamo_kw = {"region_name": REGION}
if DYNAMODB_ENDPOINT:
    dynamo_kw["endpoint_url"] = DYNAMODB_ENDPOINT
    dynamo_kw["aws_access_key_id"] = "local"
    dynamo_kw["aws_secret_access_key"] = "local"
dynamo = boto3.resource("dynamodb", **dynamo_kw).Table(TABLE)

PAGE = """
<!DOCTYPE html>
<html><head><meta charset="utf-8"><title>Visitor Board</title>
<style>body{font-family:system-ui;max-width:640px;margin:2rem auto;padding:0 1rem;}
.instance{background:#f0f0f0;padding:.2rem .5rem;border-radius:4px;}
table{width:100%%;border-collapse:collapse;} th,td{text-align:left;padding:.4rem;border-bottom:1px solid #ddd;}
th{background:#232f3e;color:#fff;} button{padding:.5rem 1rem;background:#ff9900;border:none;border-radius:4px;cursor:pointer;}
.error{background:#fce4e4;padding:.5rem;border-radius:4px;margin:.5rem 0;}
</style></head><body>
<h1>Visitor Board</h1>
<p>Served by: <span class="instance">{{ instance_id }}</span> (DynamoDB)</p>
{% if error %}<div class="error">{{ error }}</div>{% endif %}
<form method="post" action="/">
  <input name="message" placeholder="Say something..." required>
  <button type="submit">Post</button>
</form>
<h2>Messages</h2>
<table><tr><th>Message</th><th>Time</th><th>Instance</th></tr>
{% for m in messages %}
<tr><td>{{ m.message }}</td><td>{{ m.timestamp }}</td><td><code>{{ m.instanceId }}</code></td></tr>
{% else %}
<tr><td colspan="3">No messages yet.</td></tr>
{% endfor %}
</table></body></html>
"""


@app.route("/")
def index():
    """Read from shared data tier (DynamoDB). Stateless: no in-memory state."""
    try:
        items = dynamo.scan().get("Items", [])
        messages = sorted(items, key=lambda x: x.get("timestamp", ""), reverse=True)
    except Exception as e:
        messages, error = [], str(e)
    else:
        error = request.args.get("error")
    return render_template_string(
        PAGE, messages=messages, instance_id=INSTANCE_ID, error=error
    )


@app.route("/", methods=["POST"])
def post_message():
    """Write to shared data tier (DynamoDB). Any instance can later serve this."""
    msg = (request.form.get("message") or "").strip() or "(no text)"
    item = {
        "id": str(uuid.uuid4()),
        "message": msg,
        "timestamp": __import__("datetime").datetime.utcnow().isoformat() + "Z",
        "instanceId": INSTANCE_ID,
    }
    dynamo.put_item(Item=item)
    return redirect("/")


@app.route("/health")
def health():
    """For ALB/ASG health checks; no dependency on data tier."""
    return {"ok": True, "instanceId": INSTANCE_ID}


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", 3000)))
