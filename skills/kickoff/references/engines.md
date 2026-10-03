# Engines: who does which part of a kickoff

The orchestrating session spends its tokens on judgment. Hunting is delegated.

## Choosing the hunter engine

1. Local notes (`~/.claude/skill-notes/kickoff.md`) say which: use that.
2. Else, if the user wants to save Claude usage, or Codex is their preferred worker:
   `bash <skill-dir>/scripts/hunt-codex.sh --check`. If it prints OK, use Codex.
3. Else Sonnet subagents (or the cheapest capable model the harness offers).

Mixing is fine: e.g. Codex for GitHub repo hunts, Sonnet for skill-registry hunts.
Tell the user in one line which engine is doing what.

## The hunt brief (same for every engine)

Write one brief per gap x kind to a temp file:

```markdown
GAP: <capability name>
NEED: <one sentence, no solution in it>
CONSTRAINTS: <stack, licence, budget, local-only, ...>
KIND: skills-and-plugins | repos
KEYWORDS: <5-10 terms incl. synonyms and domain jargon>
ALREADY INSTALLED (don't re-suggest): <names>
SEARCH BUDGET: <e.g. max 8 gh repo searches, 3 gh code searches; see rate limits in sources.md>
SOURCES + QUERIES: <paste the relevant section of references/sources.md>
RETURN: JSON per schemas/candidates.json, 3-8 candidates, ranked by fit.
```

## Engine: Codex CLI (OpenAI tokens)

```bash
bash <skill-dir>/scripts/hunt-codex.sh --brief /tmp/kickoff/<slug>/<gap>-<kind>.md \
  --out /tmp/kickoff/<slug>/<gap>-<kind>.json --effort medium
```

- Runs `codex exec` in a throwaway dir with network on and workspace writes confined there,
  enforces the JSON schema, and lowers reasoning effort (narrow search doesn't need max).
- Run several in parallel with `&` and `wait`, or as background Bash calls.
- `--check` failing with "requires a newer version of Codex" means the CLI is older than
  the configured model: the user should upgrade Codex (`brew upgrade codex` /
  `npm i -g @openai/codex@latest`). Fall back to Sonnet meanwhile, and say so.

## Engine: Sonnet subagent (Claude Code)

Spawn all hunters in one message so they run concurrently:

```
Agent(description: "kickoff hunt: <gap> <kind>", model: "sonnet",
      subagent_type: "general-purpose",
      prompt: "<the brief> + Never install, clone or modify anything. Verify repo facts with
               gh api. Read README/SKILL.md before listing. Return only the JSON.")
```

## Engine: deep-mode repo readers

In deep mode, for each CLONE/BORROW candidate, a Sonnet subagent (or Codex) reads the tree
and the 3-10 files that matter, and reports: what's reusable, the mechanics that would
break (concurrency, idempotency, state transitions, money as floats), licence per package.
They save files they read into `/tmp/kickoff/<slug>/repos/<owner>__<repo>/`, with the
permalink at the commit SHA on the first line.

## Waiting on hunters

Hunters usually return in 2-5 minutes; a repo hunter that hits the search rate limit can take
longer. Don't idle: while they run, do the inventory mapping and draft the report skeleton
from phases 1-3. Fold results in as they arrive. If a hunter hasn't returned after ~8
minutes, finish without it and list its gap as "hunt incomplete" in open questions.

## What stays with the orchestrator

Recall (phase 1), gap analysis (phase 3), vetting and safety reads of anything to be
installed (phase 5), and the plan (phase 6). Hunter output is a lead: re-verify any number
or claim that goes into the report.
