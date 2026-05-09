# AGENTS.md

This file provides guidance to Codex Desktop and Codex CLI when working with this repository.

## Local collaboration rules

- Always use the `caveman` skill at `ultra` level.
- Never commit to `master`; create draft MRs/PRs for integration work.

## Repo purpose

Source repo for five portable agent skills implementing the **LLM Wiki** pattern:

- `wiki-ingest/SKILL.md` files new knowledge into the wiki.
- `wiki-query/SKILL.md` searches the wiki before re-researching.
- `wiki-lint/SKILL.md` health-checks structure, orphans, contradictions, and gaps.
- `wiki-before/SKILL.md` queries the wiki at the start of systematic debugging or brainstorming.
- `wiki-after/SKILL.md` judges and ingests reusable findings at the end of systematic debugging or brainstorming.

There is no build system and no runtime dependency. Each skill is one self-contained `SKILL.md`. Codex plugin support is provided by `.codex-plugin/plugin.json` and `hooks/hooks.json`.

## Hardcoded wiki path

All five `SKILL.md` files hardcode the absolute path `/Users/adrianbadarau/code/llm-wiki`. This is deliberate: skills run cwd-independent and must reach the same wiki regardless of which project invokes them. When editing, keep paths absolute and consistent across all skills. Forks need a global find/replace.

## Codex support

- Codex plugin discovery uses `.codex-plugin/plugin.json`.
- The manifest points `skills` at `./` so the existing root-level `wiki-*` skill directories remain compatible with Claude Code installs.
- `hooks/hooks.json` wires `wiki-before` into `UserPromptSubmit` and `wiki-after` into `Stop`.
- Hook scripts emit both Codex Desktop/Claude-style `hookSpecificOutput.additionalContext` and SDK-style top-level `additionalContext` so Codex Desktop and CLI builds can consume the reminder.

## Editing the skills

- Frontmatter `description` fields drive auto-activation. Preserve trigger keywords such as "save this", "remember this", "what do we know about X", "lint the wiki", `systematic-debugging`, and `brainstorming`.
- Keep the division of labor clean: `wiki-ingest` writes, `wiki-query` reads, `wiki-lint` audits, `wiki-before`/`wiki-after` orchestrate.
- `wiki-lint` is report-only. Do not add auto-fix behavior without explicit user confirmation.
- `wiki-before` and `wiki-after` must not duplicate wiki read/write logic. They delegate to `wiki-query` and `wiki-ingest`.

## Testing changes

No test suite exists. Verify syntax with:

```bash
python3 -m json.tool .codex-plugin/plugin.json >/dev/null
python3 -m json.tool hooks/hooks.json >/dev/null
find . -maxdepth 3 -name 'SKILL.md' -print
```

For behavior, install into Claude Code or Codex and trigger the relevant skill phrase from a real session.
