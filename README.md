# kickoff

**A Claude Code skill for the start of anything bigger: find what already exists before you build.**

When you start a new project, Claude usually starts from zero. It doesn't check what you
decided last month, which of your installed skills fit, whether a well-built skill for this
exists, or whether someone on GitHub already solved half of it. `/kickoff` does all four,
then hands you a plan to approve.

```
/kickoff a local meeting recorder that turns my mic audio into searchable facts
```

```
Kicking off: checking what we already know, what's installed, and what exists.

What we already know
- Agents run on subscription CLIs, not paid APIs (memory: user profile)
- Shared knowledge lives in a markdown folder with local recall (knowledge/INDEX.md)

Plan by capability
| Capability  | Decision | What                                 | Why                         |
|-------------|----------|--------------------------------------|-----------------------------|
| capture     | BORROW   | <repo>: audio/recorder.ts            | solved device switching     |
| transcribe  | INSTALL  | <owner>/<repo>@transcribe            | local whisper, MIT, active  |
| extract     | USE      | claude-api (installed)               | already covers it           |
| storage     | CLONE    | <owner>/<repo> as reference          | same schema problem         |
| evals       | BUILD    | -                                    | nothing fits; looked at 4   |

Proposed installs (need your OK)
1. npx skills add <owner>/<repo>@transcribe   scope: project   read: SKILL.md + 1 script, no network calls
```

Nothing is installed or cloned until you approve it.

## What it does

1. **Recalls what you already know.** Reads your memory files, `CLAUDE.md`, decision logs and
   past kickoff reports, and pulls out the preferences and decisions that bear on this project.
2. **Inventories what's installed.** Lists your skills, plugins, commands and MCP servers and
   maps them to the parts of the project.
3. **Names the gaps.** Per capability: covered, partial, or gap. Also flags the gaps
   projects this size usually hit (evals, deploy, observability, security).
4. **Hunts.** Anthropic's official skills, your plugin marketplaces, skills.sh, GitHub code
   search for `SKILL.md`, curated lists, and GitHub repos that solve part or all of it.
5. **Vets with its own eyes.** Fit first; facts straight from the GitHub API, never from
   listicles; a safety read of every script and hook in anything it proposes to install.
6. **Plans.** Starts with the lightest way to test the idea before building anything (a no-code
   tool, a spreadsheet, a flag in an existing repo), then USE / INSTALL / BORROW / CLONE / BUILD
   per capability, written to `docs/kickoff/<slug>.md`, so the next session doesn't redo the hunt.

## Cheaper models do the searching

Searching is narrow and parallel; judgment isn't. kickoff runs the search jobs on a cheaper
engine and keeps your main model for recall, vetting and the plan:

- **Sonnet subagents** (default inside Claude Code), or
- **Codex CLI**, to spend your OpenAI/ChatGPT usage instead of Claude usage
  (`scripts/hunt-codex.sh`, runs in a throwaway folder with a JSON schema enforced).

## Install

```bash
git clone https://github.com/Hagetino/kickoff.git
cd kickoff
bash install.sh          # or: bash install.sh --link  (to hack on it)
```

Needs `gh` (logged in), `jq`, `curl`. Codex CLI is optional.

## Usage

| Command | What it does | Cost |
|---|---|---|
| `/kickoff` | Quick kickoff for the current task: shortlist only | ~5-10 min |
| `/kickoff deep` | Parallel hunters per gap; reads candidate repos' code | ~20-40 min |
| `/kickoff <description>` | Kickoff for a project you describe | |

It also triggers on its own when you start something clearly multi-session ("let's build",
"new project", "this could get bigger").

## Personal notes

Create `~/.claude/skill-notes/kickoff.md` to tell it where your knowledge lives, which hunter
engine you prefer, and constraints to apply to every plan (e.g. "no paid APIs", "local-only").
Where the notes disagree with the skill, the notes win. Example:

```markdown
## Where my knowledge lives
- Shared knowledge base: ~/code/notes/ (INDEX.md, decisions.md)
## Hard preferences
- No paid APIs; free/local path first.
## Engines
- Hunters: Codex, effort medium.
```

## Safety

- Read-only until you approve. Hunters are told never to install or modify anything, and
  the Codex hunter runs in a temp folder.
- Never passes auto-confirm flags (`-y`, `--yes`) to installers; prefers project-scope installs.
- Every proposed install comes with what was read and any red flags found
  (`curl | sh`, unexpected network calls, credential access, hooks).

## Files

```
skills/kickoff/
  SKILL.md                      the workflow
  references/sources.md         where to hunt and exact queries per source
  references/vetting.md         fit, health and safety rubric
  references/engines.md         Sonnet / Codex hunter routing and briefs
  schemas/candidates.json       what hunters return
  scripts/inventory.sh          installed skills, plugins, commands, MCP servers
  scripts/search-marketplaces.sh offline search of your plugin marketplaces
  scripts/repo-facts.sh         stars, licence, last push, archived, from gh api
  scripts/hunt-codex.sh         run one hunt on Codex CLI
```

## Credits

Repo-hunting techniques adapted from [kengomatsuo/agent-skills](https://github.com/kengomatsuo/agent-skills)
(MIT). See [NOTICE.md](NOTICE.md).

## License

MIT
