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
