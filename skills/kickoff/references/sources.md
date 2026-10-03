# Where to hunt, and how to query each source

## GitHub rate limits (read before dispatching hunters)

Search is rate-limited per user, and parallel hunters share the budget:
`gh search repos` 30/min, `gh search code` **10/min**. `gh api repos/...` (repo facts, trees,
file contents) uses the separate core limit (5000/hr), so verification is cheap; searching is
what's scarce. Check with `gh api rate_limit --jq '.resources.search, .resources.code_search'`.

- Give each hunter a search budget in its brief (e.g. "at most 8 repo searches, 3 code searches").
- Put skill-registry hunts on sources that don't use GitHub search (skills.sh API, local
  marketplaces, curated list READMEs via `gh api .../readme`), and leave the GitHub search budget
  to the repo hunter.
- On a 403 / "rate limit exceeded": wait 60s and retry once; don't silently skip the search.
  Report skipped queries in `notes`.

Ordered roughly by signal. Every number you plan to show the user gets re-checked with
`scripts/repo-facts.sh`: search snippets, registries and listicles are leads only.

## Skills and plugins

### 1. Already installed (free, zero risk)
`scripts/inventory.sh`. Always first. The best skill is the one you already trust.

### 2. Anthropic official
- **`anthropics/skills`** (GitHub): the reference skills (docx, pdf, xlsx, pptx, skill-creator,
  frontend-design, mcp-builder, webapp-testing, ...).
  `gh api 'repos/anthropics/skills/git/trees/HEAD?recursive=1' --jq '.tree[].path' | grep SKILL.md`
- **`anthropics/claude-plugins-official`**: the official plugin directory, usually already
  present locally as the `claude-plugins-official` marketplace. Search it offline:
  `scripts/search-marketplaces.sh <kw1> <kw2> ...`

### 3. Local plugin marketplaces
`scripts/search-marketplaces.sh` searches every marketplace the user has added
(`~/.claude/plugins/marketplaces/*`). Install path after approval:
`/plugin install <name>@<marketplace>`.

### 4. skills.sh (open agent-skills registry)
Use the search API directly. It fuzzy-matches names and is far more relevant than the
`npx skills find` CLI, which tends to surface the most-installed skills regardless of query:

```bash
curl -s "https://skills.sh/api/search?q=<1-2 words>&limit=10" \
  | jq -r '.skills[] | "\(.id)\t\(.installs)"'
```

Query with the domain noun ("transcription", "postgres", "pdf extraction"), several
synonyms, one query each. `id` is `owner/repo/skill`; the source repo is `owner/repo`.
Install counts measure popularity, not fit or safety.
Install (after approval, no `-y`): `npx skills add <owner/repo>@<skill>` (project scope by default).

### 5. GitHub code search for SKILL.md files
Finds skills that live in product repos and aren't in any registry (e.g. a vendor shipping a
skill for its own SDK):

```bash
gh search code --filename SKILL.md "<keyword>" --limit 20 \
  --json repository,path --jq '.[] | "\(.repository.nameWithOwner)\t\(.path)"'
```

A skill shipped by the vendor of the library you'll use is often the best fit there is.

### 6. Curated lists (recall, not ranking)
- `VoltAgent/awesome-agent-skills`: large, actively maintained, includes official vendor skills.
- `ComposioHQ/awesome-claude-skills`, `travisvn/awesome-claude-skills`
- `hesreallyhim/awesome-claude-code`: skills, hooks, commands, workflows, tooling.

Read the README raw and grep for your keywords:
`gh api repos/<o>/<r>/readme --jq .content | base64 -d | grep -iE '<kw1>|<kw2>'`

### 7. GitHub topics for skill collections
`gh search repos --topic=claude-skills --topic=<domain> --sort stars --limit 10`
Also try topics `agent-skills`, `claude-code-skills`, `claude-code-plugin`.

## Repos that solve part or all of the project

**Search by topics, not phrases.** `gh search repos "nextjs meeting transcription"` matches
name/description phrases and often returns nothing. Topics work:

```bash
gh search repos --topic=<domain> --topic=<stack> --sort stars --limit 10 \
  --json fullName,stargazersCount,pushedAt,description,isArchived
```

Run many combinations, then verify the survivors with `scripts/repo-facts.sh`:

- **Stack topics:** the framework, ORM, database, runtime, model provider.
- **Domain topics:** the feature's own words plus `self-hosted`, `local-first`, `open-source`.
- **Synonyms and jargon:** the words practitioners use, not the words in the user's request.
- **Other markets/languages:** when English finds nothing close, the same product often
  exists under another language's term. Nothing found in English is a reason to widen the search, not proof nothing exists.
- **Prefer the close match over the famous one:** a 300-star project in the exact stack with
  the exact table you need beats a 40k-star framework you'd have to bend.

Then read the tree before the README; the README is what a project wants to be, the tree
is what it is:

```bash
gh api "repos/<o>/<r>/git/trees/HEAD?recursive=1" --jq '.tree[].path' | grep -iE '<area words>'
```

For a BORROW decision, cite the file permalink at a commit SHA, not a branch link.

## Credits
The topic-search and tree-first techniques are adapted from `prior-art` and `code-to-copy`
in [kengomatsuo/agent-skills](https://github.com/kengomatsuo/agent-skills) (MIT).
