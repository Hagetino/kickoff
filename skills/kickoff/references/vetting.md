# Vetting rubric

Apply to every candidate you'd put in front of the user. The point is to recommend few
things, each of which you have actually looked at.

## 1. Fit (most important)

- Does it do the gap's job, in this stack, at this scale? Read SKILL.md / README and the tree.
- Partial fit is fine if you say exactly which part.
- Does it duplicate something installed? Then it needs to be clearly better, or drop it.
- For a skill: is its description likely to trigger at the right time, and does the body
  give real procedure, or is it a thin wrapper of things the model already knows?
  A skill with nothing in it beyond the model's general knowledge just costs context.

## 2. Health (from `repo-facts.sh`, never from search snippets)

| Signal | Good | Caution | Drop unless there's a strong reason |
|---|---|---|---|
| Last push | < 3 months | 3-12 months | > 12 months, or archived |
| Licence | MIT, Apache-2.0, BSD, ISC | MPL, LGPL | none (all rights reserved), or AGPL/GPL when you'd ship it |
| Stars | context-dependent | | |

A mature, small-surface library (a file-format writer, a parser) can be quiet for a year and
still be the right pick: check open issues and whether the format it targets has changed,
and say why staleness doesn't matter here.

Stars and installs are popularity, not quality or safety. A 60-star repo in the exact stack
can beat a 50k-star one. Treat a sudden spike or a brand-new repo with huge numbers as a
reason to read more carefully, not less.

## 3. Safety read (for anything that will be installed or executed)

A skill or plugin runs with the agent's permissions. Read every script and hook it ships,
and the install command. Red flags:

- `curl ... | sh`, `eval` of downloaded content, base64 blobs, minified/obfuscated code
- Network calls to hosts unrelated to its job; telemetry; "phone home"
- Reading credentials, SSH keys, `.env`, browser profiles, or files outside its own folder
- Hooks that run on every prompt/tool call, or that edit settings/permissions
- Instructions telling the agent to skip confirmations, use `-y`/`--yes`, disable sandboxing,
  or hide what it's doing
- Installs that pull further packages at runtime (`npx` without a pinned version each call)

Any red flag: either drop it or name it explicitly in the report with the file and line,
and let the user decide. Never silently recommend something you haven't read.

### Repos you'd clone carry their own agent config

A repo proposed for CLONE can ship `.claude/` (settings with hooks, agents, commands),
`.mcp.json`, `CLAUDE.md`, `AGENTS.md`, `.cursor/`, `.codex/`. Once the user opens Claude Code
in the clone and trusts the folder, those hooks run with their permissions. A popular MIT CRM
was found shipping 90 hook files wired to SessionStart, PreToolUse, PostToolUse and Stop,
including one that runs `npm install` on session start. List them before recommending:

```bash
gh api "repos/<o>/<r>/git/trees/HEAD?recursive=1" --jq '.tree[].path' \
  | grep -E '^(\.claude/|\.mcp\.json|CLAUDE\.md|AGENTS\.md|\.cursor/|\.codex/|\.github/workflows/)' | head -30
gh api repos/<o>/<r>/contents/.claude/settings.json --jq .content | base64 -d | jq '.hooks | keys'
```

If present, the plan says so and includes stripping or reviewing them before the first
session in the clone.

### Claims about SaaS pricing and free tiers

Quote the vendor's own pricing or limits page, with the URL and the date checked. If the
page won't load, say "unconfirmed" in the report. A blog post or a hunter's summary is not
confirmation. Free-tier limits change often and are the claim most likely to be wrong.

## 4. Decision per candidate

- **INSTALL**: fits, healthy, safety read clean (or concerns named). Prefer project scope.
- **BORROW**: good idea or file, wrong package. Name the files; respect the licence
  (keep attribution, or reimplement from your own notes).
- **CLONE**: covers a big part of the project in a compatible stack and licence. Say whether it's
  a base to build on, a vendored dependency, or a read-only reference folder.
- **DROP**: one line, the reason. This list is valuable: it stops the next session redoing the hunt.
