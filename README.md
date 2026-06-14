# cc-hooks

Real-time Claude Code hooks monitor. Captures all 30 hook event types, streams them to a browser dashboard with trimmed previews, collapsible JSON detail view, and full payload drill-down.

Zero dependencies. Single `node` command to run.

## Quick Start

```bash
# 1. Start the server
node ~/path/to/cc-hooks/server.mjs

# 2. Install hooks into your project
bash ~/path/to/cc-hooks/install.sh /path/to/your/project

# 3. Open the dashboard
open http://localhost:49152

# 4. Start a new Claude Code session in the hooked project — events stream live
```

## Custom Port

```bash
# Set port before install so it's baked into the hook commands
CC_HOOKS_PORT=9999 bash install.sh /path/to/project

# Start server on the same port
CC_HOOKS_PORT=9999 node server.mjs
```

Default port is `49152` (IANA dynamic/private range).

## Uninstall

```bash
bash uninstall.sh /path/to/your/project
```

Removes the `hooks` key from `.claude/settings.json`.

## Export

```bash
bash export.sh                   # → hooks-export.json
bash export.sh my-session.json   # → custom filename
```

Dumps all captured events as a time-sorted JSON array.

## Dashboard Features

- **Real-time SSE stream** with auto-reconnect
- **30 hook event types** across 8 color-coded categories: Session, Prompt, Tool, Turn, Agent, Context, System, MCP
- **Category filter chips** and text search
- **Sort options**: time ascending/descending, type A-Z/Z-A
- **Click any event** to open the detail panel with Trimmed/Full tabs
- **Collapsible JSON tree** — expand/collapse any node
- **Draggable panel resize** — drag the border to adjust detail panel width
- **Keyboard**: Esc to close detail panel
- **Auto-scroll toggle** and clear button

## Event Types

| Category | Events |
|----------|--------|
| Session  | SessionStart, Setup, SessionEnd |
| Prompt   | UserPromptSubmit, UserPromptExpansion |
| Turn     | Stop, StopFailure |
| Tool     | PreToolUse, PostToolUse, PostToolUseFailure, PostToolBatch, PermissionRequest, PermissionDenied |
| Context  | InstructionsLoaded, ConfigChange, CwdChanged, FileChanged |
| Agent    | SubagentStart, SubagentStop, TaskCreated, TaskCompleted, TeammateIdle |
| System   | WorktreeCreate, WorktreeRemove, PreCompact, PostCompact |
| MCP      | Elicitation, ElicitationResult, Notification, MessageDisplay |

## How It Works

1. `install.sh` merges hook entries into your project's `.claude/settings.json`
2. Each hook runs `hook.sh`, which reads event JSON from stdin and POSTs it to the server (fire-and-forget, never blocks Claude)
3. `server.mjs` stores full JSON to `data/`, trims large values, and broadcasts via SSE
4. `ui.html` renders the live stream with filters and collapsible detail view

## Files

| File | Purpose |
|------|---------|
| `server.mjs` | HTTP server: ingest, SSE broadcast, history, detail API, serves UI |
| `ui.html` | Single-page dashboard |
| `hook.sh` | Hook script that POSTs event JSON to the server |
| `install.sh` | Installs hooks into a project's `.claude/settings.json` |
| `uninstall.sh` | Removes hooks from a project |
| `export.sh` | Exports all captured events to a JSON file |
| `data/` | Full event JSON files (gitignored) |

## License

MIT
