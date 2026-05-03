# Setup Script Design

**Date:** 2026-05-03  
**Status:** approved

## Problem

New adopters clone the repo and don't know where or how to start. The friction is not folder creation alone — it is the full onboarding sequence: creating the wiki structure, installing the skills, replacing the hardcoded wiki path in each SKILL.md, and getting a working wiki schema file. A single script eliminates all four blockers.

## Scope

`setup.sh` at repo root. Covers:

- **A** — create wiki folder structure
- **B** — symlink skills into `~/.claude/skills/`
- **C** — replace hardcoded path in SKILL.md files
- **D** — write wiki `CLAUDE.md` schema file

## Interface

```bash
./setup.sh --wiki-path ~/my-wiki
```

Single required flag. Errors with a usage message if missing or empty. `~` is expanded to an absolute path before any operations to avoid symlink-target ambiguity. The script must be run from the repo root (skill dirs are resolved relative to the script location).

Idempotent: re-running is safe. Existing dirs, symlinks, and the wiki `CLAUDE.md` are skipped with a note.

## Steps (in order)

1. **Create wiki folders** — `mkdir -p` for `raw/`, `wiki/sources/`, `wiki/concepts/`, `wiki/entities/` under the expanded wiki path.
2. **Write `wiki/CLAUDE.md`** — embedded heredoc containing the page-conventions schema (frontmatter fields, ingest/query/lint workflows). Skips if file already exists.
3. **Create `~/.claude/skills/`** if missing.
4. **Symlink all 6 skill dirs** — `wiki-ingest`, `wiki-query`, `wiki-lint`, `wiki-before`, `wiki-after`, `devils-advocate` → `~/.claude/skills/`. Skips existing symlinks.
5. **Path replacement** — `sed` in-place on the SKILL.md files that hardcode `/Users/adrianbadarau/code/llm-wiki` (currently: `wiki-ingest`, `wiki-query`, `wiki-lint`, `wiki-after`, `devils-advocate`). Replaces with the expanded `--wiki-path` value. macOS (`sed -i ''`) vs GNU (`sed -i`) detected via `uname`.
6. **Print summary** — one line per step; green checkmark for done, yellow for skipped.

## Error Handling

- `set -euo pipefail` — any failed command aborts the script immediately.
- `--wiki-path` resolves to an existing file (not a dir) → error and exit.
- Skill dirs not found relative to script → error: "run setup.sh from the repo root".
- `sed` sanity check: after replacement, if the old hardcoded path is still present in any SKILL.md → warn but don't abort (user may have already replaced it manually).
- No rollback on partial failure — all operations are additive and idempotent; re-running after fixing the issue is safe.

## Known Tradeoff

Symlinking means path-replacement edits (`sed` step C) modify SKILL.md files inside the cloned repo, leaving them git-dirty. This is expected behavior — not a bug. Documented in README under "Configure your wiki path".

## Out of Scope

- Interactive prompts (flag-only by design)
- Node.js or Makefile variants
- Auto-updating on `git pull` (symlinks handle this; path edits are one-time)
- Windows support
