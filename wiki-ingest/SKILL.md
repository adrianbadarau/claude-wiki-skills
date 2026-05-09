---
name: wiki-ingest
description: Use when the user wants to save, file, capture, remember, or "ingest" a piece of knowledge, decision, learning, article, or finding into their personal LLM wiki — including phrases like "save this to the wiki", "remember this", "file this", "ingest [thing]", "add to my notes", "this is worth keeping", or when finishing a non-trivial investigation whose conclusions would be lost in chat history.
---

# wiki-ingest

## Overview

Files knowledge from the current working session into the user's persistent LLM Wiki at `/Users/adrianbadarau/code/llm-wiki`. The wiki is the same regardless of which project or agent invokes the skill — it is a single, global personal knowledge base.

**Core principle:** raw sources are immutable; the wiki layer is fully owned and edited by the LLM. Every ingest touches the source file, a summary page, the index, and the log — at minimum.

## Wiki Location & Layout

```
/Users/adrianbadarau/code/llm-wiki/
  raw/              # immutable sources — copy in, never edit
  wiki/             # LLM-owned markdown
    index.md        # master catalog
    log.md          # append-only activity log
    sources/        # one summary per raw source
    concepts/       # concept pages (cross-source synthesis)
    entities/       # entity pages (people, tools, projects, libraries)
  _templates/note.md
```

Create the subdirectories on first use if they don't exist. Do not touch `raw/` after a file lands there.

## When to Use

Triggers:
- User says: "ingest X", "save this", "remember this", "file this", "add to wiki", "worth keeping", "don't lose this"
- A non-trivial finding emerges during work in another project that would be useful later (a debugging discovery, a library quirk, an architectural decision, a vendor gotcha) — offer to ingest it
- User pastes an article, transcript, or doc and wants it processed
- After completing meaningful research, before context is lost

Do NOT use for:
- Project-specific conventions (those go in the project's `CLAUDE.md`)
- Trivial one-liners with no reuse value
- Sensitive credentials or secrets

## Workflow

1. **Identify the source.** Three cases:
   - **External file** (article, paper, transcript): copy into `raw/` with a slugified filename including date prefix, e.g. `raw/2026-04-30-vercel-fluid-compute.md`. Never modify it after copying.
   - **Conversational knowledge** (something learned in chat, not a file): create a synthetic raw note at `raw/notes/YYYY-MM-DD-slug.md` capturing the verbatim source material / quotes / context.
   - **URL**: fetch with the platform's web-fetch/browser tool, save the markdown to `raw/`, then proceed.

2. **Read the source fully** before writing anything to the wiki.

3. **Discuss key takeaways with the user** in 3–6 bullets. Confirm framing before filing. Skip this step only if the user explicitly says "just ingest, don't ask".

4. **Write/update the source summary** at `wiki/sources/<slug>.md` using the frontmatter contract below. Type = `source-summary`.

5. **Update concept and entity pages.** A single ingest typically touches 5–15 wiki pages. For each concept/entity meaningfully discussed in the source:
   - If a page exists: edit it. Add new claims, revise outdated ones, note contradictions explicitly with `> [!note] Contradiction with [[older-source]]: ...`.
   - If no page exists and the concept is load-bearing: create one.
   - Add bidirectional `[[wiki-links]]` between related pages.

6. **Update `wiki/index.md`.** Add the new source under `## Sources` and any new concept/entity pages under their section. One line each: `- [[page-name]] — one-line summary`.

7. **Append to `wiki/log.md`.** Format:
   ```
   ## [YYYY-MM-DD] ingest | <Source Title>
   - source: [[sources/<slug>]]
   - touched: [[page-a]], [[page-b]], [[page-c]]
   - key claim: <one sentence>
   ```

8. **Report back** to the user: what was filed, which pages changed, any contradictions surfaced.

## Frontmatter Contract

Every wiki page MUST start with:

```yaml
---
title: Page Title
type: concept | entity | source-summary | comparison
sources: [raw/2026-04-30-foo.md]
related: [[[other-page]], [[another-page]]]
created: 2026-04-30
updated: 2026-04-30
confidence: high | medium | low
---
```

Use today's date from the system context, not a guess. When updating an existing page, bump `updated:` and append the new source to `sources:`.

## Agent Compatibility

This skill is invoked from arbitrary working directories. The wiki path is absolute — never resolve relative to the cwd. Use absolute paths in every Read/Write/Edit call.

Use the platform's normal file and edit tools:
- Claude Code: `Read`, `Write`, `Edit`, `Bash`, `WebFetch`.
- Codex Desktop/CLI: shell/file reads, `apply_patch` for edits, and the available web tool for URLs.

If the user is mid-task in another project and triggers an ingest, do the ingest, then return to the prior task. Do not switch the working directory.

## Quick Reference

| Action | Path |
|---|---|
| Drop external file | `/Users/adrianbadarau/code/llm-wiki/raw/<date-slug>.<ext>` |
| Synthetic note from chat | `/Users/adrianbadarau/code/llm-wiki/raw/notes/<date-slug>.md` |
| Source summary | `/Users/adrianbadarau/code/llm-wiki/wiki/sources/<slug>.md` |
| Concept page | `/Users/adrianbadarau/code/llm-wiki/wiki/concepts/<slug>.md` |
| Entity page | `/Users/adrianbadarau/code/llm-wiki/wiki/entities/<slug>.md` |
| Index | `/Users/adrianbadarau/code/llm-wiki/wiki/index.md` |
| Log | `/Users/adrianbadarau/code/llm-wiki/wiki/log.md` |

## Common Mistakes

- **Editing `raw/`.** Never. It is the source of truth. If a source is wrong, file a corrective note that links to it, don't rewrite history.
- **Skipping the index/log update.** The wiki only stays navigable because index and log are maintained on every ingest. No exceptions, even for "small" ingests.
- **Inventing the date.** Use the date from the conversation's system context, not a guessed one.
- **Filing without reading the full source first.** Summaries written from snippets miss contradictions and cross-references.
- **One giant page per source instead of distributed updates.** A source ingest should *integrate* into existing concept/entity pages, not just dump a summary.
- **Forgetting bidirectional links.** If page A links to page B, page B should reference A in its `related:` frontmatter or body.
- **Treating it as the current project's wiki.** It is the user's *global* wiki across all projects.

## Offering Ingest Proactively

When work in another project produces a durable, reusable insight (not a project-specific bug fix), end your reply with one line offering to file it. Examples of strong signals:

- A non-obvious vendor/library quirk discovered through debugging
- An architectural decision with a clear rationale
- A comparison between two approaches
- A reference doc / URL the user reacted positively to

Skip the offer for routine fixes, project-specific config, or work the user already closed out.
