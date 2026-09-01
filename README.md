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

Declare the marketplace and plugin in each repository's
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

This makes the dependency explicit for every cloud session opened on that
repository. The connected GitHub account must be allowed to read the private
`aslan-ai` repository.

Team and Enterprise administrators can alternatively register the marketplace
for their organization from <https://claude.ai/admin-settings/plugins>.
Individual private marketplaces do not have a documented account-wide sync
flow, so repository settings are the reliable option for personal cloud
sessions.

## Update

```bash
claude plugin marketplace update aslan-ai
claude plugin update aslan-core@aslan-ai
```

Restart Claude after updating.
