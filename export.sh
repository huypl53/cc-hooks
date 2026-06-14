#!/usr/bin/env bash
# Export all captured hook events as a single JSON array, sorted by time.
# Usage: bash export.sh [output-file]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DATA_DIR="${SCRIPT_DIR}/data"
OUT="${1:-hooks-export.json}"

node -e "
  const fs = require('fs');
  const dir = '${DATA_DIR}';
  const events = fs.readdirSync(dir)
    .filter(f => f.endsWith('.json'))
    .map(f => JSON.parse(fs.readFileSync(dir + '/' + f, 'utf-8')))
    .sort((a, b) => a.ts - b.ts);
  console.log(JSON.stringify(events, null, 2));
" > "$OUT"

echo "Exported $(ls "${DATA_DIR}"/*.json 2>/dev/null | wc -l | tr -d ' ') events to ${OUT}"
