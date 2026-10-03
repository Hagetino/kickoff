#!/usr/bin/env bash
# kickoff/inventory.sh: list installed skills, plugins and slash commands with descriptions.
# Read-only. No network. Usage: inventory.sh [--project <path>] [--grep "kw1|kw2"] [--max-desc N]
# --grep keeps only entries whose name/description match (case-insensitive ERE); headers stay.
set -uo pipefail

PROJECT=""
MAXD=160
GREP=""
while [ $# -gt 0 ]; do
  case "$1" in
    --project) PROJECT="${2:-}"; shift 2 ;;
    --max-desc) MAXD="${2:-160}"; shift 2 ;;
    --grep) GREP="${2:-}"; shift 2 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

CLAUDE_HOME="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"

if [ -n "$GREP" ] && [ -z "${_KICKOFF_INNER:-}" ]; then
  args=(); [ -n "$PROJECT" ] && args+=(--project "$PROJECT"); args+=(--max-desc "$MAXD")
  _KICKOFF_INNER=1 bash "$0" "${args[@]}" | grep -iE "^(## |\(|plugin\t)|$GREP"
  exit 0
fi

# Print "name<TAB>description" from a SKILL.md / command .md frontmatter.
# Handles single-line and folded/literal (>, |) descriptions.
meta() {
  awk -v maxd="$MAXD" -v fallback="$2" '
    NR==1 && $0!="---" { exit }
    NR>1 && $0=="---" { done=1 }
    done { exit }
    /^name:/ { sub(/^name:[ \t]*/, ""); gsub(/^["\x27]|["\x27]$/, ""); name=$0; next }
    /^description:/ {
      sub(/^description:[ \t]*/, "")
      if ($0 ~ /^[>|][-+]?$/) { block=1; desc=""; next }
      gsub(/^["\x27]|["\x27]$/, ""); desc=$0; block=0; next
    }
    block && /^[ \t]+/ { line=$0; sub(/^[ \t]+/, "", line); desc = desc (desc=="" ? "" : " ") line; next }
    block { block=0 }
    END {
      if (name=="") name=fallback
      if (length(desc) > maxd) desc = substr(desc, 1, maxd-3) "..."
      printf "%s\t%s\n", name, desc
    }' "$1"
}

section() { printf '\n## %s\n' "$1"; }

list_skills() { # $1 = root dir, $2 = label
  [ -d "$1" ] || return 0
  find -L "$1" -maxdepth 4 -name SKILL.md 2>/dev/null | sort | while read -r f; do
    d="$(basename "$(dirname "$f")")"
    printf '%s\t' "$2"; meta "$f" "$d"
  done | awk -F'\t' '!seen[$2]++'   # suites often vendor nested copies; keep first per name
}

section "User skills ($CLAUDE_HOME/skills)"
list_skills "$CLAUDE_HOME/skills" "user"

if [ -n "$PROJECT" ]; then
  section "Project skills ($PROJECT/.claude/skills)"
  list_skills "$PROJECT/.claude/skills" "project"
  if [ -d "$PROJECT/.claude/commands" ]; then
    section "Project commands"
    for f in "$PROJECT"/.claude/commands/*.md; do [ -e "$f" ] && { printf 'project-cmd\t'; meta "$f" "$(basename "$f" .md)"; }; done
  fi
fi

section "Installed plugins (and their skills)"
IP="$CLAUDE_HOME/plugins/installed_plugins.json"
if [ -f "$IP" ] && command -v jq >/dev/null 2>&1; then
  jq -r '.plugins | to_entries[] | .key as $k | .value[] | "\($k)\t\(.scope)\t\(.installPath)"' "$IP" 2>/dev/null |
  while IFS=$'\t' read -r key scope path; do
    printf 'plugin\t%s\t(scope: %s)\n' "$key" "$scope"
    list_skills "$path/skills" "  ${key%%@*}"
  done
else
  echo "(no installed_plugins.json or jq missing)"
fi

section "User slash commands ($CLAUDE_HOME/commands)"
for f in "$CLAUDE_HOME"/commands/*.md; do [ -e "$f" ] && { printf 'cmd\t'; meta "$f" "$(basename "$f" .md)"; }; done

section "MCP servers (configured names only)"
if command -v jq >/dev/null 2>&1; then
  P="${PROJECT:-$PWD}"; P="$(cd "$P" 2>/dev/null && pwd || echo "$P")"
  [ -f "$HOME/.claude.json" ] && jq -r --arg p "$P" '
    ((.mcpServers // {}) | keys[] | "mcp\tuser\t\(.)"),
    ((.projects[$p].mcpServers // {}) | keys[] | "mcp\tlocal\t\(.)")' "$HOME/.claude.json" 2>/dev/null
  [ -f "$P/.mcp.json" ] && jq -r '(.mcpServers // {}) | keys[] | "mcp\tproject\t\(.)"' "$P/.mcp.json" 2>/dev/null
fi
echo "(connector MCPs from claude.ai are not listed here; check the session's tool list)"
