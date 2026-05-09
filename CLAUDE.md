# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repo purpose

Source repo for five portable Claude Code and Codex skills implementing the **LLM Wiki** pattern:

- `wiki-ingest/SKILL.md` — files new knowledge into the wiki
- `wiki-query/SKILL.md` — searches the wiki before re-researching
- `wiki-lint/SKILL.md` — health-checks structure, surfaces orphans/contradictions/gaps
- `wiki-before/SKILL.md` — orchestration: queries wiki at start of systematic-debugging/brainstorming
- `wiki-after/SKILL.md` — orchestration: judges and ingests findings at end of systematic-debugging/brainstorming

No build, no tests, no runtime dependencies. Each skill is one self-contained `SKILL.md` (frontmatter + instructions). Edits ship by copying or symlinking the directories into `~/.claude/skills/`, copying them into `~/.codex/skills/`, or installing this checkout as a Codex plugin.

## Hardcoded wiki path

All five `SKILL.md` files hardcode the absolute path `/Users/adrianbadarau/code/llm-wiki`. This is deliberate — skills run cwd-independent and must reach the same wiki regardless of which project invokes them. When editing, keep paths absolute and consistent across all five skills. Forks need a global find/replace.

## Wiki structure the skills assume

```
llm-wiki/
  raw/                 # immutable source files
  wiki/
    index.md           # master catalog
    log.md             # append-only activity log
    sources/           # one summary per raw source
    concepts/          # cross-source synthesis
    entities/          # people, tools, projects, libraries
  CLAUDE.md            # schema/page conventions for the wiki repo itself
```

Pages carry YAML frontmatter: `title`, `type`, `sources`, `related`, `created`, `updated`, `confidence`. One ingest typically touches 5–15 pages (source summary + index + log + every relevant concept/entity page).

## Editing the skills

- Frontmatter `description` field drives skill auto-activation — phrasing matters; preserve trigger keywords ("save this", "remember this", "what do we know about X", "lint the wiki", etc.).
- Three skills are designed to compose: `wiki-ingest` writes, `wiki-query` reads, `wiki-lint` audits. Keep their division of labor clean — don't make `wiki-query` write or `wiki-ingest` lint.
- `wiki-lint` is a *report-only* skill by design. Do not add auto-fix behavior without an explicit user-confirmation step.
- Keep tool references portable. Prefer "use the platform's file/search/edit/web tools" and mention Claude Code/Codex examples only as equivalents.

## Codex integration

Codex support lives in:

- `.codex-plugin/plugin.json` — Codex plugin manifest. Its `skills` field points at `./` so the existing root-level `wiki-*` directories work without duplicating files under `skills/`.
- `hooks/hooks.json` — hook config that injects `wiki-before` guidance on `UserPromptSubmit` and `wiki-after` guidance on `Stop`.
- `AGENTS.md` — Codex repo guidance mirroring the Claude-specific notes in this file.

When changing hook text, keep it short. Hooks run often and should only remind the model when the before/after orchestration skills apply.

## Integration skills (wiki-before, wiki-after)

`wiki-before` and `wiki-after` are orchestration-only — they contain no wiki logic. `wiki-before` delegates to `wiki-query`; `wiki-after` delegates to `wiki-ingest`. When editing:
- Do not add wiki read/write logic to these files — all that stays in the core wiki-* skills.
- The judgment gate criteria in `wiki-after` are critical: non-obvious, cross-project reusable, not already covered. If the gate criteria change, update the examples table too.
- The `description` fields must explicitly name `systematic-debugging` and `brainstorming`, and must say "at the start" / "at the end" — that phrasing is how Claude knows when to auto-fire them.
- `wiki-after` fails silently on negative judgment — do not add any message to the user when the gate is not passed.

## Testing changes

No test suite. To verify a skill change, symlink/copy the directory into `~/.claude/skills/` or `~/.codex/skills/`, or install the repo as a Codex plugin, then trigger it from a real agent session with one of its trigger phrases.
