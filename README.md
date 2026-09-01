# aslan-ai

Personal Claude configuration shared across local and cloud sessions.

## What it provides

`aslan-core` injects concise communication, factual honesty, and code-comment
preferences at the start of every Claude session.

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

Two options are available:

1. Enable `aslan-core` in **Claude > Customize > Plugins** so it is synced to
   cloud sessions.
2. Declare the marketplace and plugin in a repository's
   `.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "aslan-ai": {
      "source": {
        "source": "github",
        "repo": "quentin-aslan/aslan-ai"
      }
    }
  },
  "enabledPlugins": {
    "aslan-core@aslan-ai": true
  }
}
```

The second option makes the dependency explicit for every cloud session opened
on that repository.

## Update

```bash
claude plugin marketplace update aslan-ai
claude plugin update aslan-core@aslan-ai
```

Restart Claude after updating.
