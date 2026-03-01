#!/usr/bin/env bash
# Show scaling in action: hit the ALB repeatedly and print which instance served each request.
# When ASG scales out, you'll see new instance IDs appear. Run generate_load.sh in another terminal to trigger scaling.
#
# Usage: ALB_URL=http://... ./show_scaling.sh [interval_seconds]
#    or: ./show_scaling.sh <ALB_BASE_URL> [interval_seconds]

set -e
ALB_URL="${ALB_URL:-$1}"
INTERVAL="${2:-1}"
if [[ -z "$ALB_URL" ]]; then
  echo "Usage: ALB_URL=http://<alb-dns> $0 [interval_seconds]" >&2
  echo "   or: $0 <ALB_BASE_URL> [interval_seconds]" >&2
  exit 1
fi

echo "Watching which instance serves each request (refresh every ${INTERVAL}s). Press Ctrl+C to stop."
echo "ALB: $ALB_URL"
echo "---"

while true; do
  INSTANCE=$(curl -sS --connect-timeout 2 "${ALB_URL}/health" 2>/dev/null | sed -n 's/.*"instanceId"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
  if [[ -n "$INSTANCE" ]]; then
    printf "%s  Instance: %s\n" "$(date +%H:%M:%S)" "$INSTANCE"
  else
    printf "%s  (no response or parse failed)\n" "$(date +%H:%M:%S)"
  fi
  sleep "$INTERVAL"
done
