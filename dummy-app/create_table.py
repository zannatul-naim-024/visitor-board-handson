#!/usr/bin/env python3
"""
Create the workshop_messages table (DynamoDB or DynamoDB Local).
Uses TABLE_NAME and DYNAMODB_ENDPOINT_URL from env — same as app.py.
"""
import os
import sys

import boto3

TABLE = os.environ.get("TABLE_NAME", "workshop_messages")
REGION = os.environ.get("AWS_REGION", "us-east-1")
ENDPOINT = os.environ.get("DYNAMODB_ENDPOINT_URL")

kwargs = {"region_name": REGION}
if ENDPOINT:
    kwargs["endpoint_url"] = ENDPOINT
    kwargs["aws_access_key_id"] = "local"
    kwargs["aws_secret_access_key"] = "local"

dynamo = boto3.resource("dynamodb", **kwargs)

try:
    dynamo.create_table(
        TableName=TABLE,
        KeySchema=[{"AttributeName": "id", "KeyType": "HASH"}],
        AttributeDefinitions=[{"AttributeName": "id", "AttributeType": "S"}],
        BillingMode="PAY_PER_REQUEST",
    )
    print(f"Created table: {TABLE}")
except dynamo.meta.client.exceptions.ClientError as e:
    if e.response["Error"]["Code"] != "ResourceInUseException":
        raise
    print(f"Table {TABLE} already exists.")
    sys.exit(0)
except Exception as e:
    print(f"Error: {e}", file=sys.stderr)
    sys.exit(1)
