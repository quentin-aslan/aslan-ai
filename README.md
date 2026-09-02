# aslan-ai

Personal Claude configuration shared across local and cloud sessions.

## What it provides

`aslan-core` injects concise communication, factual honesty, and code-comment
preferences at the start of every Claude session, and corrects commit
authorship.

## Install locally

```bash
claude plugin marketplace add git@github.com:quentin-aslan/aslan-ai.git
claude plugin install aslan-core@aslan-ai --scope user
```

Restart Claude, then verify:

```text
/hooks
```

The `SessionStart` hook from `aslan-core` must be listed.

## Use with Claude Code on the web

The plugin itself does not auto-load in cloud sessions. Verified live:
`enabledPlugins`/`extraKnownMarketplaces` declared only in a repository's own
committed `.claude/settings.json` is silently ignored there — an intentional
anti-supply-chain gate, so a repo can't self-enable a plugin (and its shell
hooks) on anyone who opens it. Team and Enterprise admins can register a
marketplace account-wide from <https://claude.ai/admin-settings/plugins>;
there's no such flow for an individual's private marketplace.

For a personal cloud session, get each piece directly into the target
repo's own `.claude/settings.json` instead — nothing there is gated:

- `attribution: { "commit": "", "pr": "", "sessionUrl": false }` — plain
  setting, takes effect immediately.
- A `hooks.PreToolUse` entry pointing at a copy of
  `check-git-commit.sh` committed in that repo (see this repo's own
  `.claude/settings.json` for the working example).

## Update

```bash
claude plugin marketplace update aslan-ai
claude plugin update aslan-core@aslan-ai
```

Restart Claude after updating.
