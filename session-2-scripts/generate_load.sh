#!/usr/bin/env bash
# Generate HTTP load against the ALB to help trigger CPU-based scaling.
# Run show_scaling.sh in another terminal to see which instances serve requests as capacity changes.
#
# Usage: ALB_URL=http://... ./generate_load.sh [duration_seconds] [concurrency]
#    or: ./generate_load.sh <ALB_BASE_URL> [duration_seconds] [concurrency]

set -e
ALB_URL="${ALB_URL:-$1}"
DURATION="${2:-120}"
CONCURRENCY="${3:-8}"
if [[ -z "$ALB_URL" ]]; then
  echo "Usage: ALB_URL=http://<alb-dns> $0 [duration_seconds] [concurrency]" >&2
  echo "   or: $0 <ALB_BASE_URL> [duration_seconds] [concurrency]" >&2
  exit 1
fi

echo "Generating load: $CONCURRENCY concurrent requests for ${DURATION}s against $ALB_URL"
echo "Press Ctrl+C to stop early."
echo "---"

END=$((SECONDS + DURATION))
while (( SECONDS < END )); do
  for ((i=0; i<CONCURRENCY; i++)); do
    curl -sS -o /dev/null --connect-timeout 2 "${ALB_URL}/" &
  done
  wait
done

echo "Load run finished."
