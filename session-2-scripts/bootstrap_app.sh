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