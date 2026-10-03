#!/usr/bin/env bash
# kickoff/repo-facts.sh: verified facts for GitHub repos, straight from the GitHub API.
# Usage: repo-facts.sh owner/repo [owner/repo ...]   (accepts full github.com URLs too)
# Output: TSV  repo  stars  license  pushed  archived  fork  topics  description
set -uo pipefail
command -v gh >/dev/null 2>&1 || { echo "gh (GitHub CLI) required: https://cli.github.com" >&2; exit 1; }
[ $# -ge 1 ] || { echo "usage: $0 owner/repo [...]" >&2; exit 2; }

printf 'repo\tstars\tlicense\tpushed\tarchived\tfork\ttopics\tdescription\n'
for arg in "$@"; do
  r="${arg#https://github.com/}"; r="${r#http://github.com/}"; r="${r%%.git}"
  r="$(printf '%s' "$r" | cut -d/ -f1-2)"
  gh api "repos/$r" --jq '[.full_name, .stargazers_count, (.license.spdx_id // "NONE"),
      .pushed_at[:10], .archived, .fork, ((.topics // [])[:6] | join(",")),
      ((.description // "")[0:120])] | @tsv' 2>/dev/null \
    || printf '%s\tERROR\tnot found or no access\t\t\t\t\t\n' "$r"
done
