# devils-advocate Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a `devils-advocate` skill that confrontationally interviews the user before brainstorming, integrating with the existing wiki-* skills.

**Architecture:** A single self-contained `SKILL.md` in `devils-advocate/`. Orchestration-only — delegates wiki reads to `wiki-query`, wiki writes to `wiki-ingest`, and design work to `superpowers:brainstorming`. Auto-fires at the start of `superpowers:brainstorming` and on explicit triggers. Repo's `README.md` and `CLAUDE.md` are updated to document it.

**Tech Stack:** Markdown only. No build, no deps, no tests (consistent with repo). Verification by file inspection and manual end-to-end trigger after symlinking into `~/.claude/skills/`.

**Spec:** `docs/superpowers/specs/2026-05-03-devils-advocate-design.md`

---

## File Structure

- **Create:** `devils-advocate/SKILL.md` — the skill itself.
- **Modify:** `README.md` — list the new skill in the skills overview.
- **Modify:** `CLAUDE.md` — extend the "Integration skills" guidance to cover devils-advocate.

Each file has one clear responsibility:
- `SKILL.md` — runtime behavior loaded by Claude when triggered.
- `README.md` — human-facing repo overview.
- `CLAUDE.md` — repo-specific guidance for Claude when editing this codebase.

---

## Task 1: Scaffold devils-advocate/SKILL.md with frontmatter

**Files:**
- Create: `devils-advocate/SKILL.md`

- [ ] **Step 1: Create the directory and the skill file with only frontmatter and a heading**

Create `devils-advocate/SKILL.md` with exactly:

```markdown
---
name: devils-advocate
description: Confrontationally interview the user about an idea before brainstorming begins. Surfaces hidden assumptions, contradictions against prior specs and the LLM wiki, and cheaper alternatives. Auto-fires at the start of superpowers:brainstorming and on triggers like "play devil's advocate", "push back on this", "grill me", "challenge this idea", "stress-test my plan".
---

# devils-advocate
```

- [ ] **Step 2: Verify the file parses as a skill**

Run: `head -n 6 devils-advocate/SKILL.md`
Expected output (first 6 lines):

```
---
name: devils-advocate
description: Confrontationally interview the user about an idea before brainstorming begins. Surfaces hidden assumptions, contradictions against prior specs and the LLM wiki, and cheaper alternatives. Auto-fires at the start of superpowers:brainstorming and on triggers like "play devil's advocate", "push back on this", "grill me", "challenge this idea", "stress-test my plan".
---

# devils-advocate
```

- [ ] **Step 3: Commit**

```bash
git add devils-advocate/SKILL.md
git commit -m "feat: scaffold devils-advocate skill with frontmatter"
```

---

## Task 2: Add the "When to use" and "Activation" sections

**Files:**
- Modify: `devils-advocate/SKILL.md`

- [ ] **Step 1: Append the When to use and Activation sections after the `# devils-advocate` heading**

Append exactly:

```markdown

## When to use

Use this skill to stress-test an idea **before** any design or implementation work begins. The goal is to surface load-bearing assumptions, contradictions against prior decisions, and cheaper alternatives — so the design phase starts from defensible ground.

This skill is a **gate**, not a designer. It does not produce architecture, code, or specs. It hands a sharpened context to `superpowers:brainstorming`, which does the design.

## Activation

**Auto-fire:** at the start of `superpowers:brainstorming`. The same orchestration pattern as `wiki-before` firing at the start of `systematic-debugging` / `brainstorming`.

**Manual triggers** (explicit invocation): "play devil's advocate", "push back on this", "grill me", "challenge this idea", "stress-test my plan".

**Collision rule:** if a synthesis block has already been emitted in the current conversation for the same idea, skip — do not grill the user a second time when brainstorming auto-fires after a manual grill.
```

- [ ] **Step 2: Verify the sections were appended**

Run: `grep -n "^## " devils-advocate/SKILL.md`
Expected: lines for `## When to use` and `## Activation`.

- [ ] **Step 3: Commit**

```bash
git add devils-advocate/SKILL.md
git commit -m "feat(devils-advocate): document when to use and activation rules"
```

---

## Task 3: Add the "Pre-grill exploration" section

**Files:**
- Modify: `devils-advocate/SKILL.md`

- [ ] **Step 1: Append the Pre-grill exploration section**

Append exactly:

```markdown

## Pre-grill exploration

Before the first question, gather context. Do these in parallel where possible:

1. **Codebase orientation.** `ls`, read `README.md`, scan top-level structure.
2. **Generic docs.** Read any `*.md` under `docs/`, plus `README.md`, `CLAUDE.md`, `AGENTS.md` if they exist.
3. **Prior brainstorm specs.** Read every file under `docs/superpowers/specs/*-design.md`. Treat these as established decisions — the current idea must justify any divergence.
4. **LLM wiki.** Delegate to the `wiki-query` skill with terms extracted from the user's idea. Pull related concepts, prior projects, and rejected approaches from `/Users/adrianbadarau/code/llm-wiki`.
5. **Targeted code grep.** Search the codebase for terms in the user's idea to find existing implementations.

Assemble an internal **ammunition list**: contradictions, prior decisions, and related work. Do not show this list verbatim to the user. Use it to inform questions.

If any of these sources is missing (e.g., no `docs/`, no prior specs, no wiki content for the topic), proceed without it. Do not block on missing context.
```

- [ ] **Step 2: Verify the section was appended**

Run: `grep -n "Pre-grill exploration" devils-advocate/SKILL.md`
Expected: one matching line.

- [ ] **Step 3: Commit**

```bash
git add devils-advocate/SKILL.md
git commit -m "feat(devils-advocate): document pre-grill exploration sources"
```

---

## Task 4: Add the "Grilling behavior" section

**Files:**
- Modify: `devils-advocate/SKILL.md`

- [ ] **Step 1: Append the Grilling behavior section**

Append exactly:

```markdown

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
```

- [ ] **Step 2: Verify the section was appended**

Run: `grep -n "Grilling behavior" devils-advocate/SKILL.md`
Expected: one matching line.

- [ ] **Step 3: Commit**

```bash
git add devils-advocate/SKILL.md
git commit -m "feat(devils-advocate): document grilling behavior, priorities, tone examples"
```

---

## Task 5: Add the "Termination & handoff" section

**Files:**
- Modify: `devils-advocate/SKILL.md`

- [ ] **Step 1: Append the Termination & handoff section**

Append exactly:

````markdown

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
````

- [ ] **Step 2: Verify the section was appended**

Run: `grep -n "Termination & handoff" devils-advocate/SKILL.md`
Expected: one matching line.

- [ ] **Step 3: Commit**

```bash
git add devils-advocate/SKILL.md
git commit -m "feat(devils-advocate): document termination, synthesis block, handoff"
```

---

## Task 6: Add the "Wiki ingest" section

**Files:**
- Modify: `devils-advocate/SKILL.md`

- [ ] **Step 1: Append the Wiki ingest section**

Append exactly:

```markdown

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
```

- [ ] **Step 2: Verify the section was appended**

Run: `grep -n "Wiki ingest" devils-advocate/SKILL.md`
Expected: one matching line.

- [ ] **Step 3: Commit**

```bash
git add devils-advocate/SKILL.md
git commit -m "feat(devils-advocate): document wiki ingest delegation and composition"
```

---

## Task 7: Add a closing "Non-goals" section to harden scope

**Files:**
- Modify: `devils-advocate/SKILL.md`

- [ ] **Step 1: Append the Non-goals section**

Append exactly:

```markdown

## Non-goals

- **No design output.** Do not propose architecture, file structure, or implementation details. That is `superpowers:brainstorming`'s job.
- **No code.** Do not write, edit, or scaffold code during grilling.
- **No direct wiki reads or writes.** All wiki I/O goes through `wiki-query` and `wiki-ingest`.
- **No silent re-grilling.** If brainstorming auto-fires this skill but a synthesis block was already emitted in the current conversation, skip with a one-line note ("Already grilled this idea; proceeding to design.").
- **No hostility.** Probing and direct, not abusive. The goal is sharper thinking, not discouragement.
```

- [ ] **Step 2: Verify the section was appended and the file is complete**

Run: `grep -c "^## " devils-advocate/SKILL.md`
Expected: `7` (When to use, Activation, Pre-grill exploration, Grilling behavior, Termination & handoff, Wiki ingest, Non-goals).

- [ ] **Step 3: Commit**

```bash
git add devils-advocate/SKILL.md
git commit -m "feat(devils-advocate): add non-goals section"
```

---

## Task 8: Update README.md to list the new skill

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Read the current README to find the skills list**

Run: `grep -n "wiki-" README.md | head -20`
Identify where the existing skills are enumerated (typically a bullet list near the top describing each skill).

- [ ] **Step 2: Add a `devils-advocate` entry to the skills list**

In the bulleted skills list (the same one that lists `wiki-ingest`, `wiki-query`, `wiki-lint`, `wiki-before`, `wiki-after`), append:

```markdown
- `devils-advocate/SKILL.md` — confrontationally interviews the user before brainstorming; auto-fires at the start of `superpowers:brainstorming` and on triggers like "grill me", "push back on this", "play devil's advocate"
```

Place it immediately after the `wiki-after` bullet so the integration skills sit together.

- [ ] **Step 3: Verify the entry is present**

Run: `grep -n "devils-advocate" README.md`
Expected: at least one matching line.

- [ ] **Step 4: Commit**

```bash
git add README.md
git commit -m "docs: list devils-advocate skill in README"
```

---

## Task 9: Update CLAUDE.md to document devils-advocate

**Files:**
- Modify: `CLAUDE.md`

- [ ] **Step 1: Locate the "Integration skills" section**

Run: `grep -n "Integration skills" CLAUDE.md`
Expected: the heading `## Integration skills (wiki-before, wiki-after)`.

- [ ] **Step 2: Rename the heading and add devils-advocate guidance**

Use Edit to replace the heading and add a new subsection. Replace:

```markdown
## Integration skills (wiki-before, wiki-after)

`wiki-before` and `wiki-after` are orchestration-only — they contain no wiki logic. `wiki-before` delegates to `wiki-query`; `wiki-after` delegates to `wiki-ingest`. When editing:
```

with:

```markdown
## Integration skills (wiki-before, wiki-after, devils-advocate)

`wiki-before`, `wiki-after`, and `devils-advocate` are orchestration-only — they contain no wiki logic. `wiki-before` delegates to `wiki-query`; `wiki-after` delegates to `wiki-ingest`; `devils-advocate` delegates to both `wiki-query` (pre-grill exploration) and `wiki-ingest` (post-grill transcript capture), and hands off to `superpowers:brainstorming`. When editing:
```

- [ ] **Step 3: Append a devils-advocate-specific subsection at the end of "Integration skills"**

Find the end of the existing "Integration skills" section (just before the next `##` heading) and append:

```markdown

### devils-advocate specifics

- The skill is **orchestration-only**. Do not add wiki I/O directly — always delegate to `wiki-query` and `wiki-ingest`.
- The frontmatter `description` must contain both the auto-fire phrasing ("Auto-fires at the start of superpowers:brainstorming") and the manual trigger phrases ("play devil's advocate", "push back on this", "grill me", "challenge this idea", "stress-test my plan"). That phrasing is how Claude knows when to invoke it.
- The collision rule (skip if already grilled in this conversation) is load-bearing — keep it explicit in the SKILL.md.
- Two ingests per idea (this skill + `wiki-after`) is intentional. Do not "deduplicate" by removing one.
- Tone is devil's advocate, not hostile. The example exchanges in the SKILL.md anchor the tone — keep them when editing.
```

- [ ] **Step 4: Verify both changes landed**

Run: `grep -n "devils-advocate" CLAUDE.md`
Expected: at least 3 matching lines (heading, intro paragraph, subsection).

- [ ] **Step 5: Commit**

```bash
git add CLAUDE.md
git commit -m "docs: extend CLAUDE.md integration-skills guidance for devils-advocate"
```

---

## Task 10: End-to-end manual verification

**Files:**
- None (manual verification only).

This task confirms the acceptance criteria from the spec. No code changes; verify and report.

- [ ] **Step 1: Symlink the skill into the user-level skills directory**

Run:

```bash
ln -snf /Users/adrianbadarau/code/claude-wiki-skills/devils-advocate ~/.claude/skills/devils-advocate
ls -l ~/.claude/skills/devils-advocate
```

Expected: `ls -l` shows a symlink pointing at the repo path.

- [ ] **Step 2: Confirm the SKILL.md parses (frontmatter + 7 sections)**

Run:

```bash
head -n 4 devils-advocate/SKILL.md
grep -c "^## " devils-advocate/SKILL.md
```

Expected:
- First 3 lines are the frontmatter delimiters and `name: devils-advocate`.
- `grep -c` returns `7`.

- [ ] **Step 3: Manually trigger the skill from a fresh Claude Code session**

In a new Claude Code session in a different repo (or this one), say: **"Grill me on this idea: I want to add a feature flag system."**

Verify in the session:
- Skill announces it is grilling.
- Skill performs pre-grill exploration (checks for docs, specs, queries the wiki).
- Skill asks one question at a time, in devil's-advocate tone.
- Skill terminates and offers handoff to brainstorming when assumptions are covered.
- Skill (or wiki-ingest, delegated) captures a transcript page in the wiki.

If any of these fail, file the failure and iterate on the SKILL.md before marking this task complete.

- [ ] **Step 4: Confirm the auto-fire path**

In a fresh session say: **"I want to brainstorm a new caching layer."** This should trigger `superpowers:brainstorming`, which should auto-fire `devils-advocate` first.

Verify devils-advocate runs before brainstorming starts asking design questions.

- [ ] **Step 5: No commit — verification only**

If everything passes, the implementation is complete. If not, return to the relevant task and fix.

---

## Self-review notes

- **Spec coverage:** Identity & activation → Tasks 1–2. Inputs → Task 3. Grilling behavior → Task 4. Termination & handoff → Task 5. Wiki ingest → Task 6. Non-goals/risks → Task 7. README/CLAUDE.md updates → Tasks 8–9. Acceptance criteria → Task 10.
- **Placeholders:** none. Every section appended in Tasks 1–7 contains the literal markdown to write.
- **Type consistency:** the synthesis block format in Task 5 matches the spec's "Termination & handoff" section verbatim.
