---
name: wiki-query
description: Use when the user asks a question that may have been answered or researched before, says "what do we know about X", "have we looked at this", "check the wiki", "query the wiki", "search my notes", or when starting work on a topic where prior accumulated knowledge in the user's personal LLM wiki could short-circuit re-research.
---

# wiki-query

## Overview

Searches the user's persistent LLM Wiki at `/Users/adrianbadarau/code/llm-wiki` for prior knowledge before answering or beginning research. The wiki is a single global knowledge base shared across all projects.

**Core principle:** read the index first, then drill into specific pages. Cite with `[[wiki-links]]`. Don't re-derive what's already filed.

## When to Use

Triggers:
- User explicitly asks: "what do we know about X", "check the wiki for Y", "have we ingested anything on Z"
- User asks a substantive question that sounds like it could be in their accumulated notes
- About to start research on a topic — check the wiki first to avoid redundancy
- User references something vague from past work ("that thing we read about...")

Do NOT use for:
- Questions clearly about the current project's code (use the project itself)
- Trivial factual questions answerable without context
- When the user is mid-task in unrelated work and didn't ask

## Workflow

1. **Read `wiki/index.md` first.** It is the catalog. Look for matching entity, concept, or source pages.

2. **If the index is empty or the topic isn't listed,** grep the wiki:
   ```
   grep -rli "<keyword>" /Users/adrianbadarau/code/llm-wiki/wiki/
   ```
   Try multiple keyword variants. Also grep `raw/` if the wiki layer comes up empty — there may be an unprocessed source.

3. **Read the matching pages fully.** Follow `[[wiki-links]]` and `related:` frontmatter to adjacent pages. Read source summaries before raw sources.

4. **Synthesize the answer with citations.** Every load-bearing claim should cite the wiki page it came from using `[[page-name]]` notation. If multiple pages contradict, surface the contradiction explicitly rather than picking a side silently.

5. **Flag gaps.** If the wiki only partially covers the question, say so plainly: "wiki has X and Y but nothing on Z."

6. **Offer to file the answer back.** If the synthesis is non-trivial — a comparison, a derived conclusion, a connection between two prior sources — end with one line offering to ingest it as a new wiki page (see `wiki-ingest` skill). Good answers are themselves wiki content; chat-only answers evaporate.

## Cross-Project Usage

The wiki path is absolute. Querying does not require changing the working directory and must not. Always use absolute paths in Read/Bash.

## Quick Reference

| Goal | Tool |
|---|---|
| Catalog scan | `Read /Users/adrianbadarau/code/llm-wiki/wiki/index.md` |
| Keyword search | `grep -rli "term" /Users/adrianbadarau/code/llm-wiki/wiki/` |
| Recent activity | `grep "^## \[" /Users/adrianbadarau/code/llm-wiki/wiki/log.md \| tail -20` |
| Find raw source | `ls /Users/adrianbadarau/code/llm-wiki/raw/` |

## Common Mistakes

- **Skipping the index.** Index is the entrypoint. Reading random pages without it wastes context and misses connections.
- **Citing without reading.** Don't cite `[[page]]` you haven't actually read in this turn.
- **Treating the wiki as authoritative without confidence checks.** Look at the page's `confidence:` frontmatter and `updated:` date. A `low` confidence page from 18 months ago is a hint, not a fact.
- **Silent contradictions.** If two pages disagree, surface it. Don't pick one silently.
- **Not offering to file the synthesis.** A good cross-source answer is wiki-worthy; offer to ingest it.
