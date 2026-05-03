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
}

WIKI_PATH=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --wiki-path)
      [[ $# -lt 2 ]] && { echo "Error: --wiki-path requires a value." >&2; usage; exit 1; }
      shift
      WIKI_PATH="${1:-}"
      ;;
    -h|--help) usage; exit 0 ;;
    *) err "Unknown argument: $1" ;;
  esac
  shift
done

[[ -z "$WIKI_PATH" ]] && { usage; exit 1; }

# Expand ~ to absolute path
WIKI_PATH="${WIKI_PATH/#\~/$HOME}"

# Validate absolute path
[[ "$WIKI_PATH" = /* ]] || err "--wiki-path must be an absolute path or start with ~. Got: '$WIKI_PATH'"

# Must be run from repo root — detect by checking for a known skill dir
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ ! -d "$SCRIPT_DIR/wiki-ingest" ]]; then
  err "setup.sh must live in the repo root alongside wiki-ingest/ (wiki-ingest/ not found at $SCRIPT_DIR)."
fi

# Reject if --wiki-path points to an existing file
if [[ -e "$WIKI_PATH" && ! -d "$WIKI_PATH" ]]; then
  err "--wiki-path '$WIKI_PATH' exists but is not a directory."
fi

echo ""
echo "Setting up claude-wiki-skills → wiki at: $WIKI_PATH"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

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
