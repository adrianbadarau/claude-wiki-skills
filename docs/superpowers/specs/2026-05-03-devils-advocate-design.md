# devils-advocate skill — design

**Status:** approved
**Date:** 2026-05-03
**Repo:** `claude-wiki-skills`

## Purpose

A confrontational pre-brainstorming skill that grills the user on a proposed idea before any design work begins. It surfaces hidden assumptions, contradictions against prior decisions, and cheaper alternatives, then hands a sharpened context to `superpowers:brainstorming` so the design phase starts from defensible ground.

Inspired by [grill-with-docs](https://github.com/mattpocock/skills/blob/main/skills/engineering/grill-with-docs/SKILL.md), but adversarial in tone and integrated with the LLM Wiki for cross-project memory.

## Scope

In scope:

- A single new skill `devils-advocate` shipped as `devils-advocate/SKILL.md` alongside the existing wiki-* skills.
- Auto-fire at the start of `superpowers:brainstorming`, plus manual triggers.
- Read-only consumption of repo docs, prior specs, codebase, and llm-wiki via `wiki-query`.
- Mid/end ingest of the grilling transcript and synthesis via `wiki-ingest`.
- Handoff to `superpowers:brainstorming` with an inline synthesis block.

Out of scope:

- Test suite (repo has none).
- Build/packaging (skills ship as plain markdown).
- Any direct wiki I/O — all reads/writes delegate to `wiki-query` / `wiki-ingest`.
- Auto-fixing or modifying user code during grilling.

## Identity & activation

- **Name:** `devils-advocate`
- **File:** `/Users/adrianbadarau/code/claude-wiki-skills/devils-advocate/SKILL.md`
- **Activation:**
  - Auto-fires at the start of `superpowers:brainstorming` (mirrors how `wiki-before` fires at the start of `systematic-debugging` / `brainstorming`).
  - Manual triggers in frontmatter `description`: "play devil's advocate", "push back on this", "grill me", "challenge this idea", "stress-test my plan".
- **Tone:** devil's advocate. Polite but probing. Direct. Not hostile, not sycophantic. Refuses hand-waving.
- **Recommended answers:** only when user is stuck (≥2 weak responses on the same question) or explicitly asks.

## Inputs (pre-grill exploration)

Before the first question, the skill loads:

1. **Codebase orientation** — `ls`, `README.md`, top-level structure.
2. **Generic docs** — any `*.md` under `docs/`, plus `README.md`, `CLAUDE.md`, `AGENTS.md`.
3. **Prior brainstorm specs** — `docs/superpowers/specs/*-design.md`. These are treated as established decisions; the current idea must justify any divergence.
4. **llm-wiki** — delegates to `wiki-query` with terms extracted from the user's idea. Pulls related concepts, prior projects, rejected approaches.
5. **Targeted code grep** — searches for terms in the user's idea to find existing implementations.

The skill assembles an internal "ammunition list": contradictions, prior decisions, and related work to challenge the user against. The list is not shown verbatim; it informs the questions.

## Grilling behavior

**Per-question pattern:**

1. One question at a time.
2. Lead with the assumption being challenged ("You said X assumes Y — why?").
3. Cite ammunition when relevant ("Spec `2026-03-12-foo-design.md` decided Z. Your idea contradicts that. Reconcile.").
4. Refuse vague answers — push for specifics, evidence, or a concrete scenario.
5. Recommend an answer only on the conditions above.
6. Sharpen fuzzy terms inline.

**Challenge priorities (in order):**

1. **Necessity** — does this need to exist? What breaks if you don't build it?
2. **Contradictions vs prior specs / wiki** — flag immediately.
3. **Hidden assumptions** — surface and demand justification.
4. **Scope creep** — flag signals that the idea is multiple projects.
5. **Cheaper alternatives** — has the user considered the trivial path?

## Termination & handoff

**Termination (mix mode):**

The skill tracks whether each major assumption has been challenged at least once and whether the last 2 questions surfaced new contradictions. When the threshold is met, it asks:

> "I think we've covered the load-bearing assumptions. Ready to design, or want to push further on anything?"

The user can extend ("keep going on X"), stop early ("enough, design it"), or abandon ("you're right, this is a bad idea").

**Handoff to brainstorming:**

After termination with a proceed outcome, the skill emits an inline synthesis block:

```
## Refined problem statement
<sharpened from grilling>

## Constraints discovered
- ...

## Open questions for design
- ...

## Rejected paths (and why)
- ...

## Prior knowledge invoked
- wiki: <pages>
- specs: <files>
```

Then invokes `superpowers:brainstorming`, passing the synthesis block as opening context. Brainstorming proceeds normally; `wiki-after` still fires at its end.

**On abandonment:** skip the brainstorming handoff and jump directly to wiki ingest.

## Wiki ingest

After grilling ends — whether proceeding to design or abandoning — the skill delegates to `wiki-ingest` with:

- Full Q&A transcript.
- Synthesis block.
- Outcome tag: `proceed-to-design` | `abandoned` | `deferred`.
- Related wiki pages touched during grilling.

`wiki-ingest` decides canonical placement (typically a new `concepts/grilling-<topic>.md` page or an extension to an existing concept page with a "challenges raised" section, plus a `log.md` entry).

**Why ingest even on proceed:** rejected paths and surfaced assumptions are the most reusable artifact — future grills should retrieve them via `wiki-query`.

**Composition with wiki-after:** `wiki-after` fires at the end of `brainstorming` and ingests the final design. Two ingests are intentional — grill captures the *adversarial* thinking, `wiki-after` captures the *resolved* design.

## File structure & composition

**New file:**

- `devils-advocate/SKILL.md` — single self-contained markdown:
  - YAML frontmatter (`name`, `description` with trigger keywords plus "at the start of brainstorming").
  - Prose instructions only. No code, no deps, no build.
  - Hardcoded wiki path `/Users/adrianbadarau/code/llm-wiki` (consistent with siblings).

**Composition:**

- Reads via `wiki-query` (delegation).
- Writes via `wiki-ingest` (delegation).
- Hands off via `superpowers:brainstorming` invocation.
- No direct wiki I/O — orchestration-only, like `wiki-before` / `wiki-after`.

**Repo-side updates:**

- `README.md` — add `devils-advocate` to the skill list with a one-line summary.
- `CLAUDE.md` — extend the "Integration skills" section to include `devils-advocate` alongside `wiki-before` / `wiki-after`. Note the auto-fire-at-start-of-brainstorming pattern and the explicit manual triggers. Reinforce the orchestration-only rule (no direct wiki logic in this file).

## Frontmatter sketch

```yaml
---
name: devils-advocate
description: Confrontationally interview the user about an idea before brainstorming begins. Surfaces hidden assumptions, contradictions against prior specs and the LLM wiki, and cheaper alternatives. Auto-fires at the start of superpowers:brainstorming and on triggers like "play devil's advocate", "push back on this", "grill me", "challenge this idea", "stress-test my plan".
---
```

## Risks & open questions

- **Auto-fire collisions.** If the user invokes `devils-advocate` manually and then brainstorming triggers it again, the skill must detect "already grilled this idea in this session" and skip. Detection rule: if a synthesis block was already emitted in the current conversation, skip.
- **Ingest noise.** Every grill produces a wiki page. If users grill frequently on tiny ideas, the wiki will fill with low-value transcripts. Mitigation: `wiki-ingest`'s own judgment gate may reject trivial transcripts; rely on it rather than adding a second gate here.
- **Tone calibration.** "Polite but probing" is subjective. The SKILL.md will include 2–3 example exchanges to anchor the tone.

## Acceptance criteria

- `devils-advocate/SKILL.md` exists and parses as valid skill markdown.
- Frontmatter `description` contains both the auto-fire phrasing and all manual trigger phrases.
- `README.md` and `CLAUDE.md` reference the new skill.
- Symlinking `devils-advocate/` into `~/.claude/skills/` and saying "grill me on idea X" in a fresh Claude Code session triggers the grill flow end-to-end: pre-grill exploration → questions → synthesis → wiki ingest → brainstorming handoff.
