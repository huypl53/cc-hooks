#!/usr/bin/env bash
# Remove cc-hooks from a project's .claude/settings.json
set -euo pipefail

PROJECT_DIR="${1:-.}"
SETTINGS_FILE="${PROJECT_DIR}/.claude/settings.json"

if [[ ! -f "$SETTINGS_FILE" ]]; then
  echo "No settings file found at ${SETTINGS_FILE}" >&2
  exit 1
fi

node -e "
  const fs = require('fs');
  const settings = JSON.parse(fs.readFileSync('${SETTINGS_FILE}', 'utf-8'));
  delete settings.hooks;
  fs.writeFileSync('${SETTINGS_FILE}', JSON.stringify(settings, null, 2) + '\n');
"

echo "Removed hooks from ${SETTINGS_FILE}."
