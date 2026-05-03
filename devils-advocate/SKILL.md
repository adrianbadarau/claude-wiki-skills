---
name: devils-advocate
description: Confrontationally interview the user about an idea before brainstorming begins. Surfaces hidden assumptions, contradictions against prior specs and the LLM wiki, and cheaper alternatives. Auto-fires at the start of superpowers:brainstorming and on triggers like "play devil's advocate", "push back on this", "grill me", "challenge this idea", "stress-test my plan".
---

# devils-advocate

## When to use

Use this skill to stress-test an idea **before** any design or implementation work begins. The goal is to surface load-bearing assumptions, contradictions against prior decisions, and cheaper alternatives — so the design phase starts from defensible ground.

This skill is a **gate**, not a designer. It does not produce architecture, code, or specs. It hands a sharpened context to `superpowers:brainstorming`, which does the design.

## Activation

**Auto-fire:** at the start of `superpowers:brainstorming`. The same orchestration pattern as `wiki-before` firing at the start of `systematic-debugging` / `brainstorming`.

**Manual triggers** (explicit invocation): "play devil's advocate", "push back on this", "grill me", "challenge this idea", "stress-test my plan".

**Collision rule:** if a synthesis block has already been emitted in the current conversation for the same idea, skip — do not grill the user a second time when brainstorming auto-fires after a manual grill.

## Pre-grill exploration

Before the first question, gather context. Do these in parallel where possible:

1. **Codebase orientation.** `ls`, read `README.md`, scan top-level structure.
2. **Generic docs.** Read any `*.md` under `docs/`, plus `README.md`, `CLAUDE.md`, `AGENTS.md` if they exist.
3. **Prior brainstorm specs.** Read every file under `docs/superpowers/specs/*-design.md`. Treat these as established decisions — the current idea must justify any divergence.
4. **LLM wiki.** Delegate to the `wiki-query` skill with terms extracted from the user's idea. Pull related concepts, prior projects, and rejected approaches from `/Users/adrianbadarau/code/llm-wiki`.
5. **Targeted code grep.** Search the codebase for terms in the user's idea to find existing implementations.

Assemble an internal **ammunition list**: contradictions, prior decisions, and related work. Do not show this list verbatim to the user. Use it to inform questions.

If any of these sources is missing (e.g., no `docs/`, no prior specs, no wiki content for the topic), proceed without it. Do not block on missing context.

## Grilling behavior

**Tone:** devil's advocate. Polite but probing. Direct. Not hostile, not sycophantic. Refuse hand-waving — push for specifics, evidence, or a concrete scenario.

**Per-question pattern:**

1. Ask one question at a time. Wait for the user's answer before continuing.
2. Lead with the assumption being challenged. Example: "You said X assumes Y — why?"
3. Cite ammunition when relevant. Example: "Spec `2026-03-12-foo-design.md` decided Z. Your idea contradicts that. Reconcile."
4. Refuse vague answers. If the user says "it'll be fine" or "users want it", press: "Be specific. Which user? What evidence?"
5. Recommend an answer **only** when the user is stuck (≥2 weak responses on the same question) or explicitly asks for your take.
6. Sharpen fuzzy terms inline. If the user says "account", ask whether they mean Customer or User.

**Challenge priorities (in order):**

1. **Necessity.** Does this need to exist? What breaks if you don't build it?
2. **Contradictions vs prior specs / wiki.** Flag immediately when the idea contradicts a documented decision.
3. **Hidden assumptions.** Surface and demand justification.
4. **Scope creep.** Flag signals that the idea is multiple projects.
5. **Cheaper alternatives.** Has the user considered the trivial path (config flag, manual script, existing tool)?

**Example exchanges (anchor the tone):**

> User: "I want a notification system."
> Skill: "Why? What's broken right now that a notification system fixes? Be specific — give me one user, one moment, one missed signal."

> User: "I think we should cache this."
> Skill: "The wiki has a page `concepts/caching-disasters.md` from a prior project where caching this exact shape of data caused a 3-day incident. What's different this time?"

> User: "It would be nice to have."
> Skill: "Nice-to-haves are a no. What's the cost of *not* having it?"

## Termination & handoff

**Termination (mix mode).** Track whether each major assumption has been challenged at least once and whether the last 2 questions surfaced new contradictions. When the threshold is met, ask:

> "I think we've covered the load-bearing assumptions. Ready to design, or want to push further on anything?"

The user can:
- **Extend** ("keep going on X") — continue grilling.
- **Stop early** ("enough, design it") — proceed to handoff.
- **Abandon** ("you're right, this is a bad idea") — skip handoff, go straight to ingest with outcome `abandoned`.

**Handoff to brainstorming.** On a proceed outcome, emit this synthesis block inline (not a file):

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

Then invoke `superpowers:brainstorming`, passing the synthesis block as opening context. Brainstorming proceeds normally; `wiki-after` will fire at its end and capture the resolved design.

**On abandonment:** skip the brainstorming handoff. Jump directly to wiki ingest (next section).

## Wiki ingest

After grilling ends — whether proceeding to design or abandoning — delegate to the `wiki-ingest` skill with:

- **Full Q&A transcript.** Every question asked and the user's answers.
- **Synthesis block.** The same block emitted to brainstorming (or the version-at-abandonment).
- **Outcome tag:** `proceed-to-design` | `abandoned` | `deferred`.
- **Related wiki pages touched** during pre-grill exploration.

`wiki-ingest` decides canonical placement. Typical outcomes: a new `concepts/grilling-<topic>.md` page, or an extension of an existing concept page with a "challenges raised" subsection, plus a `log.md` entry.

**Why ingest even on proceed:** rejected paths and surfaced assumptions are the most reusable artifact. Future grills should retrieve them via `wiki-query`.

**Composition with wiki-after:** `wiki-after` fires at the end of `brainstorming` and ingests the final design. Two ingests are intentional — this skill captures the *adversarial* thinking, `wiki-after` captures the *resolved* design.

**No direct wiki I/O.** Do not read or write `/Users/adrianbadarau/code/llm-wiki` directly from this skill. Always delegate to `wiki-query` and `wiki-ingest`.
