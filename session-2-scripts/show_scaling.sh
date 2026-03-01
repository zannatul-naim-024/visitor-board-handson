#!/usr/bin/env bash
# Show scaling in action: hit the ALB repeatedly and print which instance served each request.
# When ASG scales out, you'll see new instance IDs appear. Run generate_load.sh in another terminal to trigger scaling.
#
# Usage: ALB_URL=http://... ./show_scaling.sh [interval_seconds]
#    or: ./show_scaling.sh <ALB_BASE_URL> [interval_seconds]

set -e
SAVE_ALB_URL="${ALB_URL:-}"
ALB_URL="${ALB_URL:-$1}"
if [[ -z "$ALB_URL" ]]; then
  echo "Usage: ALB_URL=http://<alb-dns> $0 [interval_seconds]" >&2
  echo "   or: $0 <ALB_BASE_URL> [interval_seconds]" >&2
  exit 1
fi
# When ALB_URL came from env, $1 is interval; otherwise $1 is URL, $2 is interval
if [[ -n "$SAVE_ALB_URL" ]]; then
  INTERVAL="${1:-1}"
else
  INTERVAL="${2:-1}"
fi
# Ensure URL has a scheme so curl works
if [[ "$ALB_URL" != http://* && "$ALB_URL" != https://* ]]; then
  ALB_URL="http://${ALB_URL}"
fi

# instance -> "count|last_seen"
declare -A SEEN

while true; do
  INSTANCE=$(curl -sS --connect-timeout 2 "${ALB_URL}/health" 2>/dev/null | sed -n 's/.*"instanceId"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
  TS=$(date +%H:%M:%S)
  if [[ -z "$INSTANCE" ]]; then
    INSTANCE="(no response)"
  fi
  if [[ -z "${SEEN[$INSTANCE]}" ]]; then
    SEEN[$INSTANCE]="1|$TS"
  else
    C="${SEEN[$INSTANCE]%%|*}"; L="${SEEN[$INSTANCE]#*|}"
    SEEN[$INSTANCE]="$((C + 1))|$TS"
  fi

  clear
  printf "\n  ALB: %s\n" "$ALB_URL"
  printf "  Refresh: every %ss  |  Press Ctrl+C to stop\n\n" "$INTERVAL"
  printf "  %-25s  |  %6s  |  %-10s\n" "Instance" "Count" "Last Seen"
  printf "  %-25s  +  %-6s  +  %-10s\n" "-------------------------" "------" "----------"
  for inst in "${!SEEN[@]}"; do
    C="${SEEN[$inst]%%|*}"; L="${SEEN[$inst]#*|}"
    printf "  %-25s  |  %6s  |  %-10s\n" "$inst" "$C" "$L"
  done | sort
  printf "\n"

  sleep "$INTERVAL"
done
