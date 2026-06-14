#!/usr/bin/env bash
# Claude Code hook script — reads event JSON from stdin, POSTs to cc-hooks server.
# Exits 0 always so it never blocks Claude Code.

CC_HOOKS_PORT="${CC_HOOKS_PORT:-49152}"
CC_HOOKS_URL="http://localhost:${CC_HOOKS_PORT}/ingest"

payload=$(cat)

# Fire and forget — don't block the hook
curl -s -X POST "$CC_HOOKS_URL" \
  -H "Content-Type: application/json" \
  -d "$payload" \
  --max-time 1 \
  >/dev/null 2>&1 &

exit 0
