#!/usr/bin/env bash
# Generate HTTP load against the ALB to trigger scaling (e.g. "request count per target" or CPU).
# Run show_scaling.sh in another terminal to see which instances serve requests as capacity changes.
#
# Usage: ALB_URL=http://... ./generate_load.sh [duration_seconds] [concurrency]
#    or: ./generate_load.sh <ALB_BASE_URL> [duration_seconds] [concurrency]

set -e
SAVE_ALB_URL="${ALB_URL:-}"
ALB_URL="${ALB_URL:-$1}"
if [[ -z "$ALB_URL" ]]; then
  echo "Usage: ALB_URL=http://<alb-dns> $0 [duration_seconds] [concurrency]" >&2
  echo "   or: $0 <ALB_BASE_URL> [duration_seconds] [concurrency]" >&2
  exit 1
fi
# When ALB_URL came from env, $1 $2 are duration and concurrency; otherwise $1 is URL, $2 $3 are duration and concurrency
if [[ -n "$SAVE_ALB_URL" ]]; then
  DURATION="${1:-300}"
  CONCURRENCY="${2:-32}"
else
  DURATION="${2:-300}"
  CONCURRENCY="${3:-32}"
fi
# Ensure URL has a scheme so curl works
if [[ "$ALB_URL" != http://* && "$ALB_URL" != https://* ]]; then
  ALB_URL="http://${ALB_URL}"
fi

echo "Generating load: $CONCURRENCY concurrent requests for ${DURATION}s against $ALB_URL"
echo "(Scaling triggers when e.g. request count per target or CPU exceeds your policy target.)"
echo "Press Ctrl+C to stop early."
echo "---"

END=$((SECONDS + DURATION))
while (( SECONDS < END )); do
  for ((i=0; i<CONCURRENCY; i++)); do
    curl -sS -o /dev/null --connect-timeout 2 "${ALB_URL}/health" &
  done
  wait
done

echo "Load run finished."
