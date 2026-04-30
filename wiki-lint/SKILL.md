---
name: wiki-lint
description: Use when the user says "lint the wiki", "health check the wiki", "audit my notes", "find orphans", "check for contradictions in the wiki", or asks for a periodic review of their personal LLM wiki to surface stale claims, missing pages, broken links, or topics worth investigating next.
---

# wiki-lint

## Overview

Health-checks the user's LLM Wiki at `/Users/adrianbadarau/code/llm-wiki`. Surfaces structural issues, contradictions, and gaps. This is a *report* skill — produce findings, then ask the user which to act on. Do not auto-fix without permission.

## When to Use

Triggers:
- User says: "lint", "audit the wiki", "health check", "find orphans", "what's stale"
- After a batch of ingests, to consolidate
- Periodically (e.g. user invokes via `/schedule`)

Do NOT use for:
- Single-page edits (use direct Read/Edit)
- Content questions (use `wiki-query`)

## Checks

Run all of these and produce one consolidated report.

1. **Frontmatter validity** — every `wiki/**/*.md` has the required fields (`title`, `type`, `sources`, `related`, `created`, `updated`, `confidence`). List violators.

2. **Broken `[[wiki-links]]`** — find links pointing to pages that don't exist. Suggest creation or rename.

3. **Orphan pages** — pages with no inbound links from any other wiki page. Either link them in or flag for deletion.

4. **Missing concept/entity pages** — terms mentioned in 3+ pages but lacking their own page. Candidates for promotion.

5. **Contradictions** — pages making conflicting claims. Look for opposing assertions across sources of similar topic. Surface for user review.

6. **Stale claims** — pages where `updated:` is old and a newer source in `raw/` covers the same topic but hasn't been integrated. Cross-check `wiki/log.md`.

7. **Index drift** — pages existing on disk but not listed in `wiki/index.md`, or index entries pointing to deleted pages.

8. **Source coverage** — files in `raw/` with no matching `wiki/sources/<slug>.md` summary. Unprocessed ingests.

9. **Suggested next questions** — based on gaps and connections in the wiki, list 3–5 questions worth investigating to deepen the knowledge base.

## Workflow

1. **Inventory.** List all files under `wiki/` and `raw/`.
2. **Run the checks above** sequentially. For each, collect findings.
3. **Produce a single report** organized by check, with file paths and one-line descriptions.
4. **Recommend top 3 actions** ranked by impact.
5. **Wait for user direction** before fixing anything. Lint is read-only by default.
6. **Append a log entry:**
   ```
   ## [YYYY-MM-DD] lint
   - findings: <N orphans, M broken links, K stale, ...>
   - recommended: <top action>
   ```

## Cross-Project Usage

Wiki path is absolute. Run from any working directory. Do not `cd` into the wiki.

## Quick Reference

| Check | Command |
|---|---|
| All wiki pages | `find /Users/adrianbadarau/code/llm-wiki/wiki -name '*.md'` |
| Wiki-link extraction | `grep -roh '\[\[[^]]*\]\]' /Users/adrianbadarau/code/llm-wiki/wiki/ \| sort -u` |
| Frontmatter scan | `grep -L '^type:' /Users/adrianbadarau/code/llm-wiki/wiki/**/*.md` |
| Recent log | `grep "^## \[" /Users/adrianbadarau/code/llm-wiki/wiki/log.md \| tail -20` |
| Unprocessed raw | compare `ls raw/` vs `ls wiki/sources/` |

## Common Mistakes

- **Auto-fixing without permission.** Lint reports; the user decides. Especially for deletions and merges.
- **Running checks in isolation.** A broken link and an orphan and a missing concept may be the same underlying issue (a page that should exist) — connect them in the report.
- **Skipping the log entry.** Lint passes are themselves wiki history; record them.
- **Treating low-confidence pages as bugs.** `confidence: low` is a deliberate signal, not a defect. Don't flag it unless the page is also stale.
