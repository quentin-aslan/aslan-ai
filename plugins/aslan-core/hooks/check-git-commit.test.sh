#!/usr/bin/env bash
# Tests de plugins/aslan-core/hooks/check-git-commit.sh.
# Usage : bash plugins/aslan-core/hooks/check-git-commit.test.sh
set -uo pipefail

HOOK="$(dirname "$0")/check-git-commit.sh"
fail=0

check() {
  local desc="$1" payload="$2" expect="$3" # expect: deny|allow
  local out
  out="$(printf '%s' "$payload" | bash "$HOOK")"
  if [ "$expect" = "deny" ]; then
    if printf '%s' "$out" | grep -q '"permissionDecision":"deny"'; then
      echo "OK   - $desc"
    else
      echo "FAIL - $desc (attendu: deny, obtenu: '$out')"
      fail=1
    fi
  else
    if [ -z "$out" ]; then
      echo "OK   - $desc"
    else
      echo "FAIL - $desc (attendu: rien, obtenu: '$out')"
      fail=1
    fi
  fi
}

WORK="$(mktemp -d)"
git -C "$WORK" init -q

git -C "$WORK" config user.name "Claude"
git -C "$WORK" config user.email "noreply@anthropic.com"

check "identite Claude par defaut -> deny" \
  "$(jq -n --arg cwd "$WORK" '{tool_name:"Bash",cwd:$cwd,tool_input:{command:"git commit -m x"}}')" deny

check "chaine add && commit, identite Claude -> deny" \
  "$(jq -n --arg cwd "$WORK" '{tool_name:"Bash",cwd:$cwd,tool_input:{command:"git add -A && git commit -m x"}}')" deny

check "trailer Co-Authored-By Claude dans le message -> deny" \
  "$(jq -n --arg cwd "$WORK" '{tool_name:"Bash",cwd:$cwd,tool_input:{command:"git commit -m \"x\n\nCo-Authored-By: Claude <noreply@anthropic.com>\""}}')" deny

check "author deja explicite -> allow (meme avec identite Claude)" \
  "$(jq -n --arg cwd "$WORK" '{tool_name:"Bash",cwd:$cwd,tool_input:{command:"git commit --author=\"Quentin Aslan <contact@quentinaslan.com>\" -m x"}}')" allow

git -C "$WORK" config user.name "Quentin @ Vasco"
git -C "$WORK" config user.email "quentin@vasco.example"

check "identite pro deja configuree -> allow" \
  "$(jq -n --arg cwd "$WORK" '{tool_name:"Bash",cwd:$cwd,tool_input:{command:"git commit -m x"}}')" allow

check "commande non liee a git commit -> allow" \
  '{"tool_name":"Bash","tool_input":{"command":"ls -la"}}' allow

check "tool_name non Bash -> allow" \
  '{"tool_name":"Read","tool_input":{"file_path":"x"}}' allow

rm -rf "$WORK"

if [ "$fail" -eq 0 ]; then
  echo "Tous les tests sont passes."
else
  echo "Des tests ont echoue."
fi
exit $fail
