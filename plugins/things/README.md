# things: Things 3 MCP server (macOS)

Claude reads and writes Quentin's Things 3, with his rules enforced in code. Method: `~/DEV/jarvis-data/docs/context/things-method.md`. Design and review: [PLAN.md](PLAN.md).

## Tools
| Tool | Does |
|---|---|
| `things_list` | Open to-dos of inbox / today / upcoming / anytime / someday / waiting / logbook, with ids |
| `things_search` | Search titles and notes of open to-dos |
| `things_add` | Create a to-do (when, deadline, tags, area, project, source, waiting_until) |
| `things_complete` | Complete one id |
| `things_schedule` | Move one id to today / anytime / someday / inbox / a date |
| `things_update` | Rename, append notes, replace tags |

## Rules (server-side)
- No delete, no bulk tool; max 25 writes per session.
- Today capped at 9 open to-dos: the write is refused, Claude must ask what to move out.
- `waiting_until` → "⏳ " prefix + tag `En attente` + scheduled on the check date; a ⏳ title without it is refused.
- complete / schedule / update only on ids returned earlier in the same session.

## Install
- Claude Code: `claude plugin marketplace update aslan-ai && claude plugin install things@aslan-ai --scope user`, then restart.
- Claude Desktop (no plugin variables): in `~/Library/Application Support/Claude/claude_desktop_config.json`
  ```json
  "mcpServers": { "things": { "command": "/usr/bin/python3", "args": ["/Users/quentinaslan/DEV/aslan-ai/plugins/things/server.py"] } }
  ```
  then restart Desktop. First call: macOS asks to let Claude control Things3 → Allow (System Settings › Privacy & Security › Automation).

## Runtime
- Stdio: the client starts it with each session and stops it on quit. Nothing to relaunch; after a code change restart Desktop or `/mcp` reconnect.
- ~12 MB RSS (measured 2026-11-12, `/usr/bin/python3` 3.9); each call spawns a short `osascript` (~0.5-1.5 s).
- Things is launched on demand by macOS if it is closed.

## Test
```
/usr/bin/python3 test_server.py                # offline: protocol + rules, fake Things
THINGS_LIVE=1 /usr/bin/python3 test_server.py  # + read-only smoke against the real app
```

## Known Things quirks
- JXA `move` fails ("Can't convert types") → list moves go through `move.applescript` (argv, no interpolation).
- JXA `whose({status: 'open'})` fails → filter in JS on bulk-fetched `status()`.
- New JXA to-dos land in Inbox; This Evening is not scriptable.
