#!/usr/bin/env bash
# Install cc-hooks into a Claude Code project.
# Usage: /path/to/cc-hooks/install.sh [project-dir]
#
# Adds hook entries to <project>/.claude/settings.json that pipe
# every hook event to the cc-hooks server.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HOOK_PATH="${SCRIPT_DIR}/hook.sh"
PROJECT_DIR="${1:-.}"
SETTINGS_DIR="${PROJECT_DIR}/.claude"
SETTINGS_FILE="${SETTINGS_DIR}/settings.json"

if [[ ! -x "$HOOK_PATH" ]]; then
  echo "Error: hook.sh not found or not executable at ${HOOK_PATH}" >&2
  exit 1
fi

mkdir -p "$SETTINGS_DIR"

# Build the hooks JSON fragment — ALL Claude Code hook event types
# Bake port into the command so hooks work even when CC_HOOKS_PORT isn't in Claude's env
CC_HOOKS_PORT="${CC_HOOKS_PORT:-49152}"
HOOK_CMD="CC_HOOKS_PORT=${CC_HOOKS_PORT} bash ${HOOK_PATH}"
HOOK_ENTRY="[{ \"matcher\": \"\", \"hooks\": [{ \"type\": \"command\", \"command\": \"${HOOK_CMD}\" }] }]"
HOOKS_FRAGMENT=$(cat <<ENDJSON
{
  "hooks": {
    "SessionStart": ${HOOK_ENTRY},
    "Setup": ${HOOK_ENTRY},
    "SessionEnd": ${HOOK_ENTRY},
    "UserPromptSubmit": ${HOOK_ENTRY},
    "UserPromptExpansion": ${HOOK_ENTRY},
    "Stop": ${HOOK_ENTRY},
    "StopFailure": ${HOOK_ENTRY},
    "PreToolUse": ${HOOK_ENTRY},
    "PermissionRequest": ${HOOK_ENTRY},
    "PermissionDenied": ${HOOK_ENTRY},
    "PostToolUse": ${HOOK_ENTRY},
    "PostToolUseFailure": ${HOOK_ENTRY},
    "PostToolBatch": ${HOOK_ENTRY},
    "InstructionsLoaded": ${HOOK_ENTRY},
    "ConfigChange": ${HOOK_ENTRY},
    "CwdChanged": ${HOOK_ENTRY},
    "FileChanged": ${HOOK_ENTRY},
    "SubagentStart": ${HOOK_ENTRY},
    "SubagentStop": ${HOOK_ENTRY},
    "TaskCreated": ${HOOK_ENTRY},
    "TaskCompleted": ${HOOK_ENTRY},
    "TeammateIdle": ${HOOK_ENTRY},
    "WorktreeCreate": ${HOOK_ENTRY},
    "WorktreeRemove": ${HOOK_ENTRY},
    "PreCompact": ${HOOK_ENTRY},
    "PostCompact": ${HOOK_ENTRY},
    "Elicitation": ${HOOK_ENTRY},
    "ElicitationResult": ${HOOK_ENTRY},
    "Notification": ${HOOK_ENTRY},
    "MessageDisplay": ${HOOK_ENTRY}
  }
}
ENDJSON
)

if [[ -f "$SETTINGS_FILE" ]]; then
  # Merge hooks into existing settings using node (available if user has Claude Code)
  node -e "
    const fs = require('fs');
    const existing = JSON.parse(fs.readFileSync('${SETTINGS_FILE}', 'utf-8'));
    const fragment = ${HOOKS_FRAGMENT};
    existing.hooks = fragment.hooks;
    fs.writeFileSync('${SETTINGS_FILE}', JSON.stringify(existing, null, 2) + '\n');
  "
  echo "Updated ${SETTINGS_FILE} with cc-hooks."
else
  echo "${HOOKS_FRAGMENT}" | node -e "
    const fs = require('fs');
    let buf = '';
    process.stdin.on('data', d => buf += d);
    process.stdin.on('end', () => {
      fs.writeFileSync('${SETTINGS_FILE}', JSON.stringify(JSON.parse(buf), null, 2) + '\n');
    });
  "
  echo "Created ${SETTINGS_FILE} with cc-hooks."
fi

echo ""
echo "Done! Start the server with:"
echo "  node ${SCRIPT_DIR}/server.mjs"
echo ""
echo "Then open http://localhost:\${CC_HOOKS_PORT:-7890} to watch events."
