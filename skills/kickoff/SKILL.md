---
name: kickoff
description: Before building something bigger, gather everything that already exists so you don't start from zero. Reads the user's own knowledge (memory files, CLAUDE.md, decision logs), checks which installed skills and plugins fit, names what's missing, then hunts skill marketplaces and GitHub for genuinely good skills and repos to install, borrow from, or clone. Ends in a use / install / borrow / build plan with an approval gate. Use whenever the user starts a new project, a new app, a substantial feature, or a new agent or system; says "let's build", "kick off", "new project", "I want to make X", "this could become something bigger"; or asks "is there a skill / repo for this", "what should we use", "has someone built this already". Use it even when they don't ask for research, if the work is clearly multi-session or likely to grow. Skip it for small one-off edits.
when_to_use: "Trigger phrases: kick off, kickoff, new project, let's build, start building, this might get bigger, before we start, what skills should we use, is there a repo for this, prior art, don't reinvent."
user-invocable: true
---

# kickoff

Start bigger work standing on what already exists: what the user has learned, what's
installed, what the skill ecosystem offers, and what open source already solved.

> **Local notes.** If `~/.claude/skill-notes/kickoff.md` exists, read it first. It holds this
> user's own knowledge paths, engine preferences and constraints. Where it disagrees with
> this file, it wins.

**Announce:** "Kicking off: checking what we already know, what's installed, and what exists."

## Why this exists

The most expensive mistake at the start of a project is building something that already
exists: a skill that would have handled half the workflow, a repo that already has the
schema, a decision the user made three weeks ago and wrote down. Each phase below exists
to catch one of those. The output is a plan the user approves, not a pile of links.

## Depth and cost

| Mode | When | What runs | Rough cost |
|---|---|---|---|
| `quick` (default) | Most kickoffs | Phases 1-3 inline, phase 4 as one batch of cheap hunters, shortlist only | 5-10 min |
| `deep` | User says deep, or the project is clearly large (new product, multi-week) | Parallel hunters per gap, candidate repos' code actually read | 20-40 min |

Say which mode you picked and why in one line. The user can always say "go deeper on X".

## Model routing: spend the expensive model on judgment only

Hunting is narrow, parallel and repetitive: run a search, list candidates, fetch facts.
Judgment is the opposite: what fits this user, what's safe, what's actually good. Route
accordingly. Full templates are in `references/engines.md`.

| Work | Engine |
|---|---|
| Recall, gap analysis, vetting, final plan | The current session's model |
| Narrow hunts (one source x one gap → candidate JSON) | A cheaper engine: a Sonnet subagent (`Agent` with `model: "sonnet"`), or Codex CLI (`scripts/hunt-codex.sh`) to spend OpenAI tokens instead of Claude tokens |
| Reading a candidate repo's code in deep mode | Sonnet subagent, one per repo |

Pick the hunter engine from the local notes if they say, otherwise: Codex when
`codex` is installed and `scripts/hunt-codex.sh --check` passes, else Sonnet subagents.
Hunters return candidates; they never install anything and never make the final call.
Their output is a lead, not a verdict: verify anything you will recommend.

## Phase 0: Frame

Write down, before searching anything:

1. **The need in one sentence, without your solution in it.** "Turn meeting audio into
   searchable facts", not "build a whisper pipeline". The sentence is what you search with.
2. **Constraints that filter candidates:** language/runtime, framework, hosting, licence
   needs, budget ("what will the user not pay for"), privacy (local-only?).
3. **Capability list:** the 4-8 parts the project will need (e.g. capture, transcribe,
   extract, store, UI, deploy, evals). Gaps are found per capability.
4. **Where the project lives** (repo path) and a short slug for the report.

If the need is too vague to write that sentence, ask one question. Otherwise proceed.

## Phase 1: Recall what the user already knows

The user's own knowledge beats anything on the internet: it encodes their preferences,
past decisions and things that already failed. Read, in order, what exists:

- Local notes (above), global `~/.claude/CLAUDE.md`, the project's `CLAUDE.md`/`AGENTS.md`.
- Memory: `~/.claude/projects/<mangled-cwd>/memory/MEMORY.md` and the entries it points to
  that look relevant. (Mangled = cwd with `/` replaced by `-`.) Also check memory dirs
  of sibling projects when the new work relates to them.
- Project knowledge: `docs/`, `docs/kickoff/` (past kickoff reports, so you don't redo a hunt),
  decision logs (`decisions.md`, ADRs, `PLAN.md`), knowledge indexes.
- Any semantic recall tool the notes name (a `recall` script, a graph memory MCP).

Pull out only what bears on this project: hard preferences ("no paid APIs",
"subscription CLIs only"), stack defaults, prior decisions, things rejected before, and
"research before building" style rules. Quote them briefly with their source file.

## Phase 2: Inventory what's installed

Run `bash <skill-dir>/scripts/inventory.sh --project <path> --grep "<kw1|kw2|...>"`
with keywords from your capability list (drop `--grep` to see everything; the full list can
be 100+ lines). It lists installed skills with descriptions, installed plugins, slash
commands and MCP servers. Map each capability from phase 0 to installed skills that cover it.

Be honest about fit: a skill that "touches" the area is not coverage. Note which
installed skills the plan should actually invoke and at which step.

## Phase 3: Name the gaps

For each capability: **covered** (name the skill/tool), **partial** (what's missing), or
**gap**. Each partial or gap becomes a hunt brief: one sentence of need, the constraints,
and keywords including synonyms and the domain's own jargon.

Before hunting, ask whether the whole thing needs building yet. Users often want to build
when a no-code tool or a few weeks on a spreadsheet would tell them if it's worth it. Look for
that option in the hunt too, and put it in the plan's "Lightest test first" line.

Also note gaps the user may not have thought of but a project this size will hit:
evals/testing, deploy, observability, security review. Mention them; don't hunt all of
them in quick mode.

## Phase 4: Hunt

Two kinds of hunt per gap. Sources and exact queries are in `references/sources.md`.

**A. Skills and plugins.** Anthropic's official skills repo, the local plugin
marketplaces (`scripts/search-marketplaces.sh <keywords>` searches them offline),
skills.sh, GitHub code search for `SKILL.md`, curated awesome-lists.
Registry search results rank by popularity, not relevance: treat them as recall, not
ranking. A 3M-install skill that doesn't fit is noise.

**B. Repos that solve part or all of it.** GitHub search by topics, not phrases;
verify each candidate's facts with `scripts/repo-facts.sh owner/repo ...`. Look for the
small well-built project in the same stack, not just the famous one.

Dispatch hunters in parallel (one per gap x kind), each with a brief that includes the
need sentence, constraints, keywords, and the candidate schema in
`schemas/candidates.json`. Ask for 3-8 candidates each, with evidence URLs.

## Phase 5: Vet, with your own eyes

For every candidate you might recommend (not every candidate found):

- **Relevance first.** Does it do what this gap needs, in this stack? Read the SKILL.md or
  README and the file tree, not the marketing.
- **Facts from the source.** Stars, licence, last push, archived, from `repo-facts.sh`.
  Never quote numbers from listicles; they are often invented.
- **Safety read** for anything that would be installed or run: scripts, hooks, install
  steps, network calls, `curl | sh`, telemetry, auto-confirm flags, anything touching
  credentials or files outside its folder. A skill runs with the agent's permissions in
  every repo it's installed for. Rubric in `references/vetting.md`.
- **Agent config in clone candidates.** A repo you'd clone may ship `.claude/` hooks,
  `.mcp.json` or `CLAUDE.md` that run once the user trusts the folder. List them (command in
  `references/vetting.md`) and put stripping/reviewing them in the plan.
- **Pricing and free-tier claims** come from the vendor's own page with the date, or are marked
  unconfirmed.
- **Overlap.** Does it duplicate something already installed? Then it's noise unless clearly better.

Drop candidates with a one-line reason. "Nothing good exists" is a valid finding.

## Phase 6: The plan

Write the report to `docs/kickoff/<slug>.md` in the project (create the folder). When the
project repo doesn't exist yet, write it to `~/.claude/kickoff/<slug>.md` and move it into
`docs/kickoff/` once the repo is created. Shape:

```markdown
# Kickoff: <project> (<date>)

**Need:** <one sentence>  **Mode:** quick|deep  **Constraints:** ...

**Recommendation:** <2-3 sentences: what you'd do and why. Be opinionated.>

**Lightest test first:** <the cheapest way to learn whether this is worth building: a no-code
tool, a spreadsheet, a free SaaS tier, a flag in an existing repo. Say what result would justify
building. "None, because ..." is fine.>

**Where it lives:** extend <existing repo> | new repo <name> | inside <repo>/<dir>, and why.
Check the user's own repos first: a sibling project often already covers part of the pipeline.

## What we already know
- <preference/decision> (source: <file>)

## Plan by capability
| Capability | Decision | What | Why | Evidence |
|---|---|---|---|---|
| transcribe | USE | installed skill X | covers it | - |
| extract | INSTALL | owner/repo@skill | fits stack, 2k stars, MIT, read SKILL.md | <url> |
| storage | BORROW | owner/repo: schema.sql | solved dedupe well | <permalink> |
| ui | CLONE | owner/repo as base | does 70% of it, same stack | <url> |
| evals | BUILD | - | nothing fits because ... | - |

## Proposed installs (need your OK)
1. `<exact command>` - scope: project | user. Safety notes: ...

## Considered and dropped
- owner/repo: <reason>

## Open questions
```

Decisions mean: **USE** (already installed), **INSTALL** (new skill/plugin),
**BORROW** (copy a pattern or file, cite the permalink), **CLONE** (take a repo as a base or
vendor it), **BUILD** (nothing fits; say what you looked at). Build is a legitimate answer
when you looked.

Then show the user a short summary in chat: the table, the proposed installs, and the
link to the file. Stop and wait for approval.

## Phase 7: Act on what's approved

- Install only what the user approved, exactly as approved. Prefer project scope over
  user/global scope, and never pass auto-confirm flags (`-y`, `--yes`) to installers:
  the confirmation is the user's last look.
- Clones go where the user says; default to a sibling folder for reference, or `vendor/`
  when it becomes part of the codebase. Check the licence allows what you'll do.
- When borrowing code, respect the licence: keep attribution, or reimplement from your own
  notes of how it works.
- Update the report with what was installed/cloned, and add a one-line pointer to the
  report wherever the project keeps decisions, so the next session doesn't redo the hunt.

## When to rerun

Re-run for a new major capability, or when a dropped candidate's reason stops holding
(licence changed, project revived). Amend the existing report with a dated section rather
than starting over.
