# Things MCP server: plan (2026-11-12)

Goal: Claude (Desktop and Code) reads and writes Quentin's Things 3 with his rules enforced in code. Method: `jarvis-data/docs/context/things-method.md`.

## Decision: own minimal server, not hald/things-mcp
| | hald/things-mcp | Ours |
|---|---|---|
| Size | ~1,550 lines, 26 tools, FastMCP + things.py + httpx | ~200 lines, stdlib only |
| Reads in Claude Desktop | Broken: issue #62 "unable to open database file" (SQLite + macOS privacy) | JXA via `osascript`: no database access, no Full Disk Access |
| Delete | No | No, by construction |
| Quentin's rules | None | Today cap 9, ⏳ needs a check date, source in notes |
| Install | `uvx` (external code, blocked by the classifier here) | Repo checkout, nothing downloaded |
Lost on purpose: logbook queries, advanced search, checklists, headings, bulk updates. Add only when a real need shows up.

## Placement
```
aslan-ai/plugins/things/
  .claude-plugin/plugin.json
  .mcp.json            # Claude Code: python3 ${CLAUDE_PLUGIN_ROOT}/server.py
  server.py            # MCP stdio JSON-RPC + tools + rules
  things.js            # JXA backend: one function per action, JSON in/out
  test_server.py       # runnable check
  README.md
```
- New plugin, not inside `aslan-core`: aslan-core loads in every session (cloud included); Things is Mac-only.
- Claude Desktop: `mcpServers.things = {command: "python3", args: ["<abs path>/plugins/things/server.py"]}` (Desktop has no `${CLAUDE_PLUGIN_ROOT}`).

## Design
- **Transport**: MCP stdio = newline-delimited JSON-RPC 2.0. Handle `initialize`, `notifications/initialized`, `ping`, `tools/list`, `tools/call`; unknown method → error -32601. Protocol version: echo the client's.
- **Backend**: `osascript -l JavaScript things.js '<json>'`, `function run(argv)`; arguments travel as JSON, never interpolated into script text (titles come from mails and messages = injection path). 15 s timeout.
- **IDs everywhere**: list results return Things `id`; complete/schedule take an `id` (titles repeat, one task has no title).
- **Known quirks encoded**: a JXA push lands in Inbox → create then `move` to the target list; never mutate a list while iterating it.

## Tools (6)
| Tool | Does | Annotations |
|---|---|---|
| `things_list` | One list: inbox, today, upcoming, anytime, someday, waiting (tag `En attente`). Returns id, title, notes (truncated), when, deadline, tags, project, area | readOnly |
| `things_search` | Title/notes substring across open to-dos | readOnly |
| `things_add` | Create a to-do: title, notes, source, list/when, deadline, tags, waiting_until | not destructive |
| `things_complete` | Mark one id completed | not destructive (undo in Things) |
| `things_schedule` | Move one id to today / evening / anytime / someday / a date | not destructive |
| `things_update` | Change title, notes (append), tags of one id | not destructive |

## Rules enforced in the server
1. No delete, no bulk tool.
2. Today cap: adding/scheduling into Today when it already holds ≥ 9 open to-dos returns an error explaining the cap; Claude must ask Quentin what to move out. No silent override.
3. Waiting: `waiting_until` (date) required → title prefixed "⏳ ", tag `En attente`, scheduled for that date.
4. `source` (e.g. "WhatsApp Gab 12/11") appended to notes on add when given.
5. Every write returns the id and the resulting list, so Claude can report what changed.

## Checks
- `test_server.py`: pipes initialize + tools/list + one read call (`things_list today`) through the real server; asserts JSON-RPC shape and that rule 2/3 validation rejects bad input without touching Things.
- Writes tested once by hand on a to-do "TEST MCP", then completed (never deleted).

## Cost and lifecycle
- Process spawned by the client over stdio: at Claude Desktop launch / each Claude Code session; dies with it. No daemon, no launchd, nothing to relaunch. After a code change: restart Desktop or `/mcp` reconnect.
- RAM: stdlib Python ≈ 10–20 MB per client [ESTIMATE, measure with `ps -o rss=`]; each osascript call is short-lived.

## Open question for Quentin
Today holds 22 open to-dos: with the cap, the first add to Today is refused. Move the 14 stale ones to Someday?

## Challenge (haiku reviewer, 2026-11-12) and what was done
| Finding | Status |
|---|---|
| Things JXA surface undocumented: verify each property/command | Verified live: id, dates, tags, area, schedule, status work; JXA `move` and `whose(status)` fail → `move.applescript` + JS filter |
| initialize must return capabilities.tools, serverInfo, a supported protocolVersion | Done; client version echoed only if supported |
| Notifications get no response; -32601 only for requests | Done, tested |
| Rule violations as `isError` tool results, -32602 for unknown tool | Done, tested |
| Annotations: explicit `destructiveHint: false` etc. | Done |
| Desktop PATH: absolute `/usr/bin/python3`, 3.9-compatible, paths from `__file__` | Done |
| Automation prompt / -1743, timeout 15 s | Mapped to a clear error |
| UTF-8 on stdio, logs on stderr only | Done; "⏳ é" tested live |
| Mass-complete via injected mail | Write budget 10/session + ids must come from this session's reads |
Rejected: per-call human approval inside the server (the client already asks before tool calls).
