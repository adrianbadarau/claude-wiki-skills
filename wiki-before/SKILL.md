---
name: wiki-before
description: Invoke at the start of systematic-debugging or brainstorming — before the first clarifying question or Phase 1 investigation begins. Queries the wiki for prior knowledge on the topic so existing findings inform the session rather than being re-derived.
---

# wiki-before

## Overview

Surfaces prior wiki knowledge before a debugging or brainstorming session begins. Delegates entirely to `wiki-query` — does not implement its own wiki reading logic.

**Core principle:** check what you already know before investigating. A 30-second wiki query can short-circuit hours of re-derivation.

## When to Use

Triggers:
- About to invoke `systematic-debugging` (any bug, test failure, unexpected behavior)
- About to invoke `brainstorming` (any new feature, design, or architectural question)

Do NOT use for:
- Mid-session (only fires at the very start, before the first real action)
- `wiki-query` triggered directly by the user (that skill handles itself)

## Hook Integration

Claude Code can auto-select this skill from the description. Codex Desktop/CLI plugin installs also inject a `UserPromptSubmit` reminder from `hooks/hooks.json`, so the skill is considered before the first real debugging or brainstorming action.

The hook is only a reminder. Still apply the `When to Use` gate above.

## Workflow

1. **Identify the topic** from the user's message: the bug being debugged, the feature being designed, the technology stack involved.

2. **Invoke the `wiki-query` skill** on that topic. Pass the topic as the query. Let `wiki-query` do all wiki reading — do not read wiki files directly in this skill.

3. **Present findings concisely:**
   - If the wiki has relevant knowledge: 2–5 bullets with `[[wiki-link]]` citations pointing to the matching pages.
   - If the wiki has nothing relevant: one line — "Wiki has no prior knowledge on this topic." — then stop. No padding, no apology.

4. **Return control immediately.** Do not start the debugging or brainstorming flow yourself — that is the job of the next skill.

## Common Mistakes

- **Reading wiki files directly.** Delegate to `wiki-query`. It handles index, grep, and link traversal correctly.
- **Padding empty results.** If the wiki is empty, say so in one line. Do not offer to help anyway or fill space.
- **Starting the debugging/brainstorming flow.** This skill's job ends after the wiki report. The next skill takes over.
- **Firing mid-session.** Only fires once, at the very start. If systematic-debugging is already underway, do not invoke this skill again.
