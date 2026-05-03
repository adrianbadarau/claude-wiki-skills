# claude-wiki-skills

Six Claude Code skills for maintaining a personal, persistent **LLM Wiki** — a structured, interlinked markdown knowledge base that the LLM builds and curates incrementally as you work across projects — plus a confrontational pre-brainstorming gate.

Implements the pattern described in [Geoffrey Litt's *LLM Wiki* idea file](https://github.com/anthropics/claude-cookbooks): instead of re-deriving knowledge from raw sources on every query (RAG), the LLM compiles knowledge once into a wiki and keeps it current. The wiki is a *compounding artifact*: cross-references are pre-built, contradictions are pre-flagged, syntheses persist.

## The skills

| Skill | Triggers on |
|---|---|
| **`wiki-ingest`** | "save this", "ingest X", "remember this", "file to wiki", or finishing a non-trivial finding worth keeping |
| **`wiki-query`** | "what do we know about X", "check the wiki", "have we ingested anything on Y" |
| **`wiki-lint`** | "lint the wiki", "audit my notes", "find orphans", "find stale claims" |
| **`wiki-before`** | Auto-fires at the start of `systematic-debugging` or `brainstorming` — queries wiki for prior knowledge |
| **`wiki-after`** | Auto-fires at the end of `systematic-debugging` or `brainstorming` — judges and files reusable findings |
| **`devils-advocate`** | Auto-fires at the start of `superpowers:brainstorming`, plus manual triggers ("grill me", "push back on this", "play devil's advocate", "challenge this idea", "stress-test my plan") — confrontationally interviews the user before design |

Each skill is self-contained in its own directory with a single `SKILL.md` (no scripts, no dependencies).

## Integration with superpowers skills

Two skills wire the wiki into the `systematic-debugging` and `brainstorming` superpowers skills automatically:

- **`wiki-before`** — fires before Phase 1 of debugging or before the first brainstorming question. Surfaces any prior wiki knowledge on the topic so it informs the session.
- **`wiki-after`** — fires after root cause is confirmed + fix verified (debugging) or after the spec is approved (brainstorming). Applies a judgment gate: only files findings that are non-obvious AND cross-project reusable AND not already well-covered in the wiki. Fails silently when the gate doesn't pass.

Both skills delegate to `wiki-query` and `wiki-ingest` respectively — they add no wiki logic of their own.

## How it works

The wiki has three layers:

1. **`raw/`** — immutable source documents you drop in (articles, notes, transcripts).
2. **`wiki/`** — LLM-owned markdown: source summaries, concept pages, entity pages, an `index.md` catalog, an append-only `log.md`.
3. **Schema** (`CLAUDE.md` / `AGENTS.md` in the wiki repo) — page conventions and workflows the LLM follows.

Every page carries YAML frontmatter (`title`, `type`, `sources`, `related`, `created`, `updated`, `confidence`). One ingest typically touches 5–15 pages: source summary + index + log + every relevant concept/entity page.

## Install

These are personal Claude Code skills. Drop them into your skills directory:

```bash
git clone https://github.com/adrianbadarau/claude-wiki-skills.git
cp -r claude-wiki-skills/wiki-* ~/.claude/skills/
```

Or symlink so this repo is the live source:

```bash
ln -s "$PWD/claude-wiki-skills/wiki-ingest"      ~/.claude/skills/wiki-ingest
ln -s "$PWD/claude-wiki-skills/wiki-query"       ~/.claude/skills/wiki-query
ln -s "$PWD/claude-wiki-skills/wiki-lint"        ~/.claude/skills/wiki-lint
ln -s "$PWD/claude-wiki-skills/wiki-before"      ~/.claude/skills/wiki-before
ln -s "$PWD/claude-wiki-skills/wiki-after"       ~/.claude/skills/wiki-after
ln -s "$PWD/claude-wiki-skills/devils-advocate"  ~/.claude/skills/devils-advocate
```

## Configure your wiki path

⚠️ **The skills currently hardcode the wiki path** to `/Users/adrianbadarau/code/llm-wiki`. Run `setup.sh` to replace it automatically:

```bash
./setup.sh --wiki-path ~/your-wiki-path
```

`setup.sh` handles: creating the wiki folder structure, symlinking the skills into `~/.claude/skills/`, replacing the hardcoded path in every `SKILL.md`, and writing a starter `CLAUDE.md` schema into your wiki repo.

**Git-dirty note:** because the skills are installed as symlinks, `setup.sh`'s path-replacement step edits the `SKILL.md` files inside this cloned repo, leaving them git-dirty. This is expected — the path is personal config, not something to commit. If you pull updates and the SKILL.md files are modified by the update, re-run `setup.sh` to re-apply your path.

If you prefer to edit manually: replace `/Users/adrianbadarau/code/llm-wiki` with your absolute wiki path in each `SKILL.md`. The path must be absolute — skills are deliberately cwd-independent.

Recommended wiki layout (the skills assume this structure, will create subdirs on first use):

```
your-llm-wiki/
  raw/                    # immutable source files — never edit after ingest
  wiki/
    index.md              # master catalog
    log.md                # append-only activity log
    sources/              # one summary per raw source
    concepts/             # concept pages (cross-source synthesis)
    entities/             # entity pages (people, tools, projects, libraries)
  CLAUDE.md               # schema / page conventions
```

A minimal `CLAUDE.md` for the wiki repo itself is included as `examples/wiki-CLAUDE.md` for reference.

## Usage from any project

The skills are global — once installed, they fire from any working directory. Examples:

- *(in your work project)* "We just figured out that Vercel Fluid Compute keeps function instances warm across concurrent requests. Worth saving." → `wiki-ingest` files it under `wiki/concepts/fluid-compute.md`, links it from `entities/vercel.md`, updates index + log.
- *(in any project)* "What do we know about feature flag rollout strategies?" → `wiki-query` reads the wiki index, drills into matching pages, answers with `[[wiki-link]]` citations.
- *(periodically)* "Lint the wiki." → `wiki-lint` reports orphans, broken links, stale claims, unprocessed raw sources, and suggests the next 3–5 questions worth investigating.

## Pairs well with

- **[Obsidian](https://obsidian.md/)** — open the wiki folder as a vault for graph view, backlinks, and live browsing of LLM edits.
- **[qmd](https://github.com/tobi/qmd)** — local hybrid BM25 + vector search for when the wiki grows past `index.md`-only navigation (~hundreds of pages).
- **Git** — the wiki is just markdown; commit it for version history.

## License

MIT.
