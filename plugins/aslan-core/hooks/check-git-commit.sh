#!/usr/bin/env bash
# Deny (not silently rewrite) a git commit that would carry Claude's
# identity or an AI attribution trailer, so nothing slips through
# unnoticed and a project's own configured identity is never touched.
set -euo pipefail

# Overridable per project.
TARGET_NAME="${ASLAN_GIT_IDENTITY_NAME:-Quentin Aslan}"
TARGET_EMAIL="${ASLAN_GIT_IDENTITY_EMAIL:-contact@quentinaslan.com}"

input="$(cat)"
tool_name="$(printf '%s' "$input" | jq -r '.tool_name // empty')"

deny() {
  jq -nc --arg reason "$1" \
    '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $reason}}'
  exit 0
}

[ "$tool_name" = "Bash" ] || exit 0

command="$(printf '%s' "$input" | jq -r '.tool_input.command // empty')"
cwd="$(printf '%s' "$input" | jq -r '.cwd // "."')"

printf '%s' "$command" | grep -qE '(^|[;&|]|[[:space:]])git[[:space:]]+commit([[:space:]]|$)' || exit 0

if printf '%s' "$command" | grep -qiE 'co-authored-by:[^"'"'"']*(claude|anthropic)|claude-session:|generated with \[?claude'; then
  deny "Retire les traces Claude du message (Co-Authored-By, Claude-Session, Generated with Claude Code) puis relance le commit."
fi

# An explicit --author means the caller already handled identity.
printf '%s' "$command" | grep -q -- '--author=' && exit 0

author_email="$(git -C "$cwd" config --get user.email 2>/dev/null || echo "")"
author_name="$(git -C "$cwd" config --get user.name 2>/dev/null || echo "")"

looks_like_claude=false
case "$author_email" in *@anthropic.com|*@anthropic.*|"") looks_like_claude=true ;; esac
case "$author_name" in [Cc]laude|[Cc]laude\ *|"") looks_like_claude=true ;; esac

if [ "$looks_like_claude" = true ]; then
  deny "Identite git actuelle (${author_name} <${author_email}>) ressemble a celle de Claude. Relance avec --author=\"${TARGET_NAME} <${TARGET_EMAIL}>\"."
fi

exit 0
