#!/usr/bin/env bash
# kickoff/search-marketplaces.sh: offline search of locally known Claude Code plugin marketplaces.
# Matches any keyword (case-insensitive) in plugin name, description, category or keywords.
# Usage: search-marketplaces.sh <keyword> [keyword...]
set -uo pipefail
[ $# -ge 1 ] || { echo "usage: $0 <keyword> [keyword...]" >&2; exit 2; }
command -v jq >/dev/null 2>&1 || { echo "jq required" >&2; exit 1; }

CLAUDE_HOME="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
ROOT="$CLAUDE_HOME/plugins/marketplaces"
[ -d "$ROOT" ] || { echo "no marketplaces at $ROOT (add one with /plugin marketplace add)"; exit 0; }

# Build a jq regex from keywords: (kw1|kw2|...)
RE="$(printf '%s|' "$@" | sed 's/|$//; s/[.[\*^$()+?{}]/\\&/g')"

found=0
for mp in "$ROOT"/*/; do
  f="$mp.claude-plugin/marketplace.json"
  [ -f "$f" ] || continue
  name="$(basename "$mp")"
  out="$(jq -r --arg re "$RE" --arg mp "$name" '
    .plugins[]? |
    select(([.name, .description, .category, ((.keywords // []) | join(" ")), ((.tags // []) | join(" "))]
            | map(. // "") | join(" ")) | test($re; "i")) |
    "\(.name)@\($mp)\t\(.category // "-")\t\((.description // "")[0:160])"' "$f" 2>/dev/null)"
  if [ -n "$out" ]; then echo "$out"; found=1; fi
done
[ "$found" = 1 ] || echo "(no matches for: $*)"
echo
echo "# install with: /plugin install <name>@<marketplace>  (only after vetting + user OK)"
