#!/usr/bin/env bash
# kickoff/hunt-codex.sh: run one narrow hunt on Codex CLI (OpenAI tokens instead of Claude tokens).
# The hunter searches and reports candidates as JSON. It is told never to install anything,
# and it runs in a throwaway directory so it cannot touch your project.
#
# Usage:
#   hunt-codex.sh --check                         # is Codex usable? (one tiny call)
#   hunt-codex.sh --brief brief.md --out out.json [--model M] [--effort low|medium|high] [--timeout SEC]
#
# Env: KICKOFF_CODEX_MODEL, KICKOFF_CODEX_EFFORT override the defaults (Codex config default model, effort medium).
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
SCHEMA="$HERE/../schemas/candidates.json"
MODEL="${KICKOFF_CODEX_MODEL:-}"
EFFORT="${KICKOFF_CODEX_EFFORT:-medium}"
TIMEOUT=600
BRIEF=""; OUT=""; CHECK=0

while [ $# -gt 0 ]; do
  case "$1" in
    --check) CHECK=1; shift ;;
    --brief) BRIEF="$2"; shift 2 ;;
    --out) OUT="$2"; shift 2 ;;
    --model) MODEL="$2"; shift 2 ;;
    --effort) EFFORT="$2"; shift 2 ;;
    --timeout) TIMEOUT="$2"; shift 2 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

command -v codex >/dev/null 2>&1 || { echo "codex: not installed (npm i -g @openai/codex or brew install codex)"; exit 1; }

# portable timeout: GNU timeout / gtimeout if present, else run without one
TO=""; command -v timeout >/dev/null 2>&1 && TO="timeout $TIMEOUT"; [ -z "$TO" ] && command -v gtimeout >/dev/null 2>&1 && TO="gtimeout $TIMEOUT"

WORK="$(mktemp -d "${TMPDIR:-/tmp}/kickoff-hunt.XXXXXX")"
trap '[ -n "${KICKOFF_KEEP:-}" ] && echo "kept $WORK" >&2 || rm -rf "$WORK"' EXIT

ARGS=(exec --skip-git-repo-check --ephemeral -C "$WORK"
      -s workspace-write -c 'sandbox_workspace_write.network_access=true'
      -c "model_reasoning_effort=\"$EFFORT\"")
[ -n "$MODEL" ] && ARGS+=(-m "$MODEL")

if [ "$CHECK" = 1 ]; then
  CTO="${TO:+${TO%% *} 120}"
  $CTO codex "${ARGS[@]}" -o "$WORK/check.txt" "Reply with exactly: OK" >"$WORK/log.txt" 2>&1
  if grep -q '^OK' "$WORK/check.txt" 2>/dev/null; then
    echo "codex: OK ($(codex --version 2>/dev/null), model: ${MODEL:-config default}, effort: $EFFORT)"; exit 0
  fi
  echo "codex: NOT usable"; grep -iE 'requires|upgrade|login|unauthor|invalid' "$WORK/log.txt" | grep -o '"message":"[^"]*"\|^[^{]*$' | sort -u | head -3
  [ -s "$WORK/log.txt" ] || echo "(no output from codex)"; exit 1
fi

[ -f "$BRIEF" ] && [ -n "$OUT" ] || { echo "need --brief <file> and --out <file>" >&2; exit 2; }

PROMPT="$(cat <<EOF
You are a research hunter for a project kickoff. Search, read, and report. Rules:
- NEVER install, clone into, or modify anything outside this scratch directory. No package installs.
- Use gh (GitHub CLI), curl, and web search. Verify stars/licence/last push with
  gh api repos/<owner>/<repo> rather than trusting search snippets or blog posts.
- Rank by fit to the need, not popularity. Read the README or SKILL.md before listing a candidate.
- Note any scripts, hooks, network calls or auto-install behaviour you see in a candidate.
- Prefer 3-8 strong candidates over a long list. Empty is fine if nothing fits; say so in notes.
- Your final message must be JSON matching the provided schema.

BRIEF:
$(cat "$BRIEF")
EOF
)"

$TO codex "${ARGS[@]}" --output-schema "$SCHEMA" -o "$OUT" "$PROMPT" >"$WORK/log.txt" 2>&1
rc=$?
if [ $rc -ne 0 ] || [ ! -s "$OUT" ]; then
  echo "hunt failed (rc=$rc). Last log lines:" >&2; tail -5 "$WORK/log.txt" >&2; exit 1
fi
echo "hunt ok -> $OUT"
