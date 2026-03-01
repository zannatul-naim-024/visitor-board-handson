#!/usr/bin/env bash
# Watch ASG capacity and instance list in the terminal — see scaling in real time.
# Requires: AWS CLI, credentials with autoscaling:DescribeAutoScalingGroups.
#
# Usage: ./watch_asg.sh <ASG_NAME> [interval_seconds]
# Example: ./watch_asg.sh workshop-asg 5

set -e
ASG_NAME="${1:?Usage: $0 <ASG_NAME> [interval_seconds]}"
INTERVAL="${2:-5}"

echo "Watching ASG: $ASG_NAME (refresh every ${INTERVAL}s). Press Ctrl+C to stop."
echo "---"

while true; do
  JSON=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names "$ASG_NAME" \
    --query 'AutoScalingGroups[0].{Desired:DesiredCapacity,Min:MinSize,Max:MaxSize,Instances:Instances[*].InstanceId}' \
    --output json 2>/dev/null) || JSON=""
  if [[ -z "$JSON" || "$JSON" == "null" ]]; then
    echo "$(date +%H:%M:%S)  (failed to describe ASG — check AWS CLI and credentials)"
  elif command -v jq &>/dev/null; then
    echo "$(date +%H:%M:%S)  Desired: $(echo "$JSON" | jq -r '.Desired')  Min: $(echo "$JSON" | jq -r '.Min')  Max: $(echo "$JSON" | jq -r '.Max')"
    echo "$JSON" | jq -r '.Instances[]? // empty' | sed 's/^/    /'
  else
    echo "$(date +%H:%M:%S)  $JSON"
  fi
  echo "---"
  sleep "$INTERVAL"
done
