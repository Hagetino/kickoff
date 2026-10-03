#!/usr/bin/env bash
set -euo pipefail

# kickoff installer: puts the skill at ~/.claude/skills/kickoff.
#   bash install.sh          copy (stable; re-run to update)
#   bash install.sh --link   symlink to this clone (edits here take effect immediately)
# No network calls. Checks for the tools the skill uses and tells you what's missing.

HERE="$(cd "$(dirname "$0")" && pwd)"
SRC="$HERE/skills/kickoff"
DEST="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills/kickoff"

echo "==> kickoff installer"
mkdir -p "$(dirname "$DEST")"
if [ -e "$DEST" ] || [ -L "$DEST" ]; then
  echo "  replacing existing $DEST"; rm -rf "$DEST"
fi
if [ "${1:-}" = "--link" ]; then
  ln -s "$SRC" "$DEST"; echo "  skill: linked $DEST -> $SRC"
else
  cp -R "$SRC" "$DEST"; echo "  skill: copied -> $DEST"
fi
chmod +x "$DEST"/scripts/*.sh

echo "  checking tools:"
for t in gh jq curl; do
  if command -v "$t" >/dev/null 2>&1; then echo "    $t: ok"; else echo "    $t: MISSING (needed)"; fi
done
gh auth status >/dev/null 2>&1 && echo "    gh auth: ok" || echo "    gh auth: not logged in (run: gh auth login)"
command -v codex >/dev/null 2>&1 && echo "    codex: found (optional hunter engine; test with scripts/hunt-codex.sh --check)" \
  || echo "    codex: not found (optional; Sonnet subagents are used instead)"

cat <<'MSG'

Done. In any Claude Code project:

  /kickoff                  quick kickoff for what you're about to build
  /kickoff deep             parallel hunters, reads candidate repos' code
  /kickoff <description>    e.g. /kickoff a local meeting recorder that extracts action items

Optional: personal notes at ~/.claude/skill-notes/kickoff.md (where your knowledge lives,
preferred hunter engine, hard constraints). See README.
MSG
