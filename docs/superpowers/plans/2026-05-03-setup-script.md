# Setup Script Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create `setup.sh` at the repo root that handles full onboarding for new claude-wiki-skills adopters in a single command.

**Architecture:** Pure bash script; flag-based (`--wiki-path`); idempotent. Runs four steps in order: create wiki folders, write wiki `CLAUDE.md`, symlink skills into `~/.claude/skills/`, replace hardcoded path in SKILL.md files. Prints a colored summary on completion.

**Tech Stack:** bash, sed, ln, mkdir. No external dependencies.

---

## File Map

| Action | Path | Responsibility |
|---|---|---|
| Create | `setup.sh` | Full onboarding script |
| Modify | `README.md` | Add git-dirty tradeoff note under "Configure your wiki path" |

---

### Task 1: Script skeleton — arg parsing, validation, path expansion

**Files:**
- Create: `setup.sh`

- [ ] **Step 1: Create the script with shebang, strict mode, usage, and arg parsing**

```bash
#!/usr/bin/env bash
set -euo pipefail

HARDCODED_PATH="/Users/adrianbadarau/code/llm-wiki"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

ok()   { echo -e "${GREEN}✓${NC} $1"; }
skip() { echo -e "${YELLOW}↩${NC} $1 (skipped — already exists)"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }
err()  { echo -e "${RED}✗${NC} $1" >&2; exit 1; }

usage() {
  echo "Usage: $0 --wiki-path <absolute-or-tilde-path>"
  echo ""
  echo "  --wiki-path   Directory where the wiki will live (created if absent)"
  echo ""
  echo "Example:"
  echo "  $0 --wiki-path ~/my-wiki"
  exit 1
}

WIKI_PATH=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --wiki-path)
      shift
      WIKI_PATH="${1:-}"
      ;;
    -h|--help) usage ;;
    *) err "Unknown argument: $1" ;;
  esac
  shift
done

[[ -z "$WIKI_PATH" ]] && usage

# Expand ~ to absolute path
WIKI_PATH="${WIKI_PATH/#\~/$HOME}"

# Must be run from repo root — detect by checking for a known skill dir
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ ! -d "$SCRIPT_DIR/wiki-ingest" ]]; then
  err "Run setup.sh from the repo root (wiki-ingest/ not found next to the script)."
fi

# Reject if --wiki-path points to an existing file
if [[ -e "$WIKI_PATH" && ! -d "$WIKI_PATH" ]]; then
  err "--wiki-path '$WIKI_PATH' exists but is not a directory."
fi

echo ""
echo "Setting up claude-wiki-skills → wiki at: $WIKI_PATH"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
```

- [ ] **Step 2: Make the script executable and verify parsing works**

```bash
chmod +x setup.sh
./setup.sh --help
```

Expected output:
```
Usage: ./setup.sh --wiki-path <absolute-or-tilde-path>
  ...
```

```bash
./setup.sh 2>&1 || true
```

Expected: exits with usage message.

- [ ] **Step 3: Commit skeleton**

```bash
git add setup.sh
git commit -m "feat(setup): add script skeleton with arg parsing and validation"
```

---

### Task 2: Step A — Create wiki folder structure

**Files:**
- Modify: `setup.sh` (append after echo block)

- [ ] **Step 1: Append folder-creation block to setup.sh**

Add after the opening echo block:

```bash
# ── Step A: Wiki folder structure ────────────────────────
DIRS=(
  "$WIKI_PATH/raw"
  "$WIKI_PATH/raw/notes"
  "$WIKI_PATH/wiki"
  "$WIKI_PATH/wiki/sources"
  "$WIKI_PATH/wiki/concepts"
  "$WIKI_PATH/wiki/entities"
)

for dir in "${DIRS[@]}"; do
  if [[ -d "$dir" ]]; then
    skip "$dir"
  else
    mkdir -p "$dir"
    ok "Created $dir"
  fi
done
```

- [ ] **Step 2: Verify folder creation**

```bash
./setup.sh --wiki-path /tmp/test-wiki-$$
ls -R /tmp/test-wiki-*/
```

Expected: `raw/`, `raw/notes/`, `wiki/`, `wiki/sources/`, `wiki/concepts/`, `wiki/entities/` all present.

- [ ] **Step 3: Verify idempotency**

```bash
./setup.sh --wiki-path /tmp/test-wiki-*
```

Expected: all lines show `↩ ... (skipped — already exists)`.

- [ ] **Step 4: Clean up test dir and commit**

```bash
rm -rf /tmp/test-wiki-*/
git add setup.sh
git commit -m "feat(setup): create wiki folder structure (step A)"
```

---

### Task 3: Step D — Write wiki CLAUDE.md schema

**Files:**
- Modify: `setup.sh` (append after step A block)

- [ ] **Step 1: Append CLAUDE.md generation block**

Add after the step A block:

```bash
# ── Step D: Wiki CLAUDE.md schema ────────────────────────
WIKI_CLAUDE="$WIKI_PATH/CLAUDE.md"
if [[ -f "$WIKI_CLAUDE" ]]; then
  skip "$WIKI_CLAUDE"
else
  cat > "$WIKI_CLAUDE" <<'SCHEMA'
# LLM Wiki Schema

## Project Structure
- `raw/` — immutable source documents. NEVER modify.
- `wiki/` — LLM-generated wiki. You own this entirely.
- `wiki/index.md` — master catalog. Update on every ingest.
- `wiki/log.md` — append-only activity log.

## Page Conventions
Every wiki page MUST have YAML frontmatter:
```
---
title: Page Title
type: concept | entity | source-summary | comparison
sources: [list of raw/ files referenced]
related: [list of wiki pages linked]
created: YYYY-MM-DD
updated: YYYY-MM-DD
confidence: high | medium | low
---
```

## Ingest Workflow
When I say "ingest [filename]":
1. Read the source file in raw/
2. Discuss key takeaways with me
3. Create/update a summary page in wiki/sources/
4. Update wiki/index.md
5. Update all relevant concept and entity pages
6. Append an entry to wiki/log.md

## Query Workflow
When I ask a question:
1. Read wiki/index.md to find relevant pages
2. Read those pages
3. Synthesize an answer with [[wiki-link]] citations
4. If the answer is valuable, offer to file it as a new wiki page

## Lint Workflow
When I say "lint":
1. Check for contradictions between pages
2. Find orphan pages with no inbound links
3. List concepts mentioned but lacking own page
4. Check for stale claims superseded by newer sources
5. Suggest questions to investigate next
SCHEMA
  ok "Wrote $WIKI_CLAUDE"
fi
```

- [ ] **Step 2: Verify schema file is written**

```bash
./setup.sh --wiki-path /tmp/test-wiki-$$
cat /tmp/test-wiki-$$/CLAUDE.md
```

Expected: file present with full schema content.

- [ ] **Step 3: Verify skip on re-run**

```bash
./setup.sh --wiki-path /tmp/test-wiki-*
```

Expected: CLAUDE.md line shows `↩ ... (skipped — already exists)`.

- [ ] **Step 4: Clean up and commit**

```bash
rm -rf /tmp/test-wiki-*/
git add setup.sh
git commit -m "feat(setup): write wiki CLAUDE.md schema from heredoc (step D)"
```

---

### Task 4: Step B — Create skills dir and symlinks

**Files:**
- Modify: `setup.sh` (append after step D block)

- [ ] **Step 1: Append symlink block**

Add after the step D block:

```bash
# ── Step B: Skills symlinks ───────────────────────────────
SKILLS_DIR="$HOME/.claude/skills"
mkdir -p "$SKILLS_DIR"

SKILLS=(
  wiki-ingest
  wiki-query
  wiki-lint
  wiki-before
  wiki-after
  devils-advocate
)

for skill in "${SKILLS[@]}"; do
  src="$SCRIPT_DIR/$skill"
  dst="$SKILLS_DIR/$skill"
  if [[ ! -d "$src" ]]; then
    err "Skill directory not found: $src — run setup.sh from the repo root."
  fi
  if [[ -L "$dst" ]]; then
    skip "~/.claude/skills/$skill"
  else
    ln -s "$src" "$dst"
    ok "Symlinked ~/.claude/skills/$skill → $src"
  fi
done
```

- [ ] **Step 2: Verify symlinks (run from a temp dir first to avoid touching real skills)**

```bash
# Preview what would be linked (dry check — do not run if skills already installed)
ls -la "$HOME/.claude/skills/" 2>/dev/null | grep wiki || echo "no wiki skills yet"
```

Run the script pointing at a throwaway wiki path:

```bash
./setup.sh --wiki-path /tmp/test-wiki-$$
ls -la ~/.claude/skills/ | grep -E "wiki|devils"
```

Expected: 6 symlinks present, all pointing into the repo.

- [ ] **Step 3: Verify skip on re-run**

```bash
./setup.sh --wiki-path /tmp/test-wiki-*
```

Expected: all 6 skill lines show `↩ ... (skipped — already exists)`.

- [ ] **Step 4: Clean up test wiki dir and commit**

```bash
rm -rf /tmp/test-wiki-*/
git add setup.sh
git commit -m "feat(setup): symlink skills into ~/.claude/skills (step B)"
```

---

### Task 5: Step C — Replace hardcoded path in SKILL.md files

**Files:**
- Modify: `setup.sh` (append after step B block)

- [ ] **Step 1: Append path-replacement block**

Add after the step B block:

```bash
# ── Step C: Replace hardcoded wiki path in SKILL.md files ─
SKILL_MDS=(
  "$SCRIPT_DIR/wiki-ingest/SKILL.md"
  "$SCRIPT_DIR/wiki-query/SKILL.md"
  "$SCRIPT_DIR/wiki-lint/SKILL.md"
  "$SCRIPT_DIR/wiki-after/SKILL.md"
  "$SCRIPT_DIR/devils-advocate/SKILL.md"
)

# Detect sed flavour (macOS vs GNU)
if sed --version 2>/dev/null | grep -q GNU; then
  SED_INPLACE=(sed -i)
else
  SED_INPLACE=(sed -i '')
fi

for skill_md in "${SKILL_MDS[@]}"; do
  if grep -q "$HARDCODED_PATH" "$skill_md"; then
    "${SED_INPLACE[@]}" "s|$HARDCODED_PATH|$WIKI_PATH|g" "$skill_md"
    ok "Replaced path in $skill_md"
  else
    skip "No hardcoded path found in $skill_md"
  fi
done

# Sanity check: warn if old path still present anywhere
if grep -rl "$HARDCODED_PATH" "$SCRIPT_DIR" --include="SKILL.md" 2>/dev/null | grep -q .; then
  warn "Old hardcoded path still present in some SKILL.md files — you may have already replaced it manually."
fi
```

- [ ] **Step 2: Verify path replacement**

```bash
# First, check current state of one SKILL.md
grep "llm-wiki" wiki-ingest/SKILL.md | head -3
```

Run script against a test wiki path:

```bash
./setup.sh --wiki-path /tmp/my-test-wiki
grep "/tmp/my-test-wiki" wiki-ingest/SKILL.md | head -3
```

Expected: lines now show `/tmp/my-test-wiki` instead of `/Users/adrianbadarau/code/llm-wiki`.

- [ ] **Step 3: Restore the original path (since this is your personal repo)**

```bash
git checkout wiki-ingest/SKILL.md wiki-query/SKILL.md wiki-lint/SKILL.md wiki-after/SKILL.md devils-advocate/SKILL.md
```

- [ ] **Step 4: Commit**

```bash
git add setup.sh
git commit -m "feat(setup): replace hardcoded wiki path in SKILL.md files (step C)"
```

---

### Task 6: Completion message

**Files:**
- Modify: `setup.sh` (append at the end)

- [ ] **Step 1: Append completion block**

Add at the very end of the script:

```bash
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}Setup complete.${NC}"
echo ""
echo "Next steps:"
echo "  1. Restart Claude Code (or run /reload-plugins) to pick up the new skills."
echo "  2. Drop a file into $WIKI_PATH/raw/ and say 'ingest it' to start your wiki."
echo ""
echo "Note: the SKILL.md files in this repo now contain your wiki path and are"
echo "git-dirty by design. See README.md § 'Configure your wiki path'."
echo ""
```

- [ ] **Step 2: Verify full run end-to-end against a fresh path**

```bash
./setup.sh --wiki-path /tmp/e2e-wiki-$$
```

Expected output (all green checkmarks for a fresh run):
```
Setting up claude-wiki-skills → wiki at: /tmp/e2e-wiki-...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✓ Created /tmp/e2e-wiki-.../raw
✓ Created /tmp/e2e-wiki-.../raw/notes
...
✓ Wrote /tmp/e2e-wiki-.../CLAUDE.md
✓ Symlinked ~/.claude/skills/wiki-ingest → ...
...
✓ Replaced path in .../wiki-ingest/SKILL.md
...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Setup complete.
...
```

- [ ] **Step 3: Restore SKILL.md files to original path and clean up**

```bash
git checkout wiki-ingest/SKILL.md wiki-query/SKILL.md wiki-lint/SKILL.md wiki-after/SKILL.md devils-advocate/SKILL.md
rm -rf /tmp/e2e-wiki-*/
```

- [ ] **Step 4: Commit**

```bash
git add setup.sh
git commit -m "feat(setup): add completion message with next-steps guidance"
```

---

### Task 7: Update README with git-dirty tradeoff note

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Read the current "Configure your wiki path" section**

```bash
grep -n "Configure your wiki path\|hardcode\|fork\|find.replace" README.md
```

- [ ] **Step 2: Add git-dirty note and setup.sh usage after the existing warning block**

Find this paragraph in README.md:

```
⚠️ **The skills currently hardcode the wiki path** to `/Users/adrianbadarau/code/llm-wiki`. If you fork, edit each `SKILL.md` and replace that absolute path with your own wiki location. The path must be absolute — the skills are deliberately cwd-independent so they fire correctly when invoked from any project.
```

Replace it with:

```
⚠️ **The skills currently hardcode the wiki path** to `/Users/adrianbadarau/code/llm-wiki`. Run `setup.sh` to replace it automatically:

```bash
./setup.sh --wiki-path ~/your-wiki-path
```

`setup.sh` handles: creating the wiki folder structure, symlinking the skills into `~/.claude/skills/`, replacing the hardcoded path in every `SKILL.md`, and writing a starter `CLAUDE.md` schema into your wiki repo.

**Git-dirty note:** because the skills are installed as symlinks, `setup.sh`'s path-replacement step edits the `SKILL.md` files inside this cloned repo, leaving them git-dirty. This is expected — the path is personal config, not something to commit. If you pull updates and the SKILL.md files are modified by the update, re-run `setup.sh` to re-apply your path.

If you prefer to edit manually: replace `/Users/adrianbadarau/code/llm-wiki` with your absolute wiki path in each `SKILL.md`. The path must be absolute — skills are deliberately cwd-independent.
```

- [ ] **Step 3: Verify README renders correctly**

```bash
grep -A 20 "Configure your wiki path" README.md
```

- [ ] **Step 4: Commit**

```bash
git add README.md
git commit -m "docs: add setup.sh usage and git-dirty note to README"
```

---

## Self-Review Checklist

**Spec coverage:**
- [x] A — create wiki folder structure → Task 2
- [x] B — symlink skills → Task 4
- [x] C — path replacement + sed macOS/GNU detection → Task 5
- [x] D — write wiki CLAUDE.md → Task 3
- [x] `--wiki-path` flag required, error if missing → Task 1
- [x] `~` expansion → Task 1
- [x] Repo-root guard → Task 1
- [x] Existing-file guard → Task 1
- [x] Idempotency for dirs, symlinks, CLAUDE.md → Tasks 2, 3, 4
- [x] Sanity check after sed → Task 5
- [x] Colored summary output → Tasks 2–6 (ok/skip/warn/err helpers in Task 1)
- [x] README git-dirty note → Task 7

**No placeholders:** all steps contain complete bash code.

**Type/name consistency:** `HARDCODED_PATH`, `WIKI_PATH`, `SCRIPT_DIR`, `SKILLS_DIR`, `SKILL_MDS`, `SED_INPLACE` — consistent across all tasks.
