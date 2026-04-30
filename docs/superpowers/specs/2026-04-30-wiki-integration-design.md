# Wiki Integration Design

**Date:** 2026-04-30
**Status:** Approved

## Goal

Automatically connect the LLM Wiki to the `systematic-debugging` and `brainstorming` superpowers skills so that:
- Prior wiki knowledge surfaces **before** each session begins
- Reusable findings are filed **after** each session completes
- No user prompt required — fully automatic

## File Structure

Two new skill directories added to `claude-wiki-skills/`, installed alongside the existing three:

```
claude-wiki-skills/
  wiki-ingest/SKILL.md       (existing)
  wiki-query/SKILL.md        (existing)
  wiki-lint/SKILL.md         (existing)
  wiki-before/SKILL.md       (new)
  wiki-after/SKILL.md        (new)
```

Install by copying or symlinking into `~/.claude/skills/` — same as existing skills.

## Skill: `wiki-before`

### Trigger description

> "Invoke at the start of systematic-debugging or brainstorming — before the first clarifying question or Phase 1 investigation begins. Queries the wiki for prior knowledge on the topic so existing findings inform the session rather than being re-derived."

### Behavior

1. Identify the topic from context (bug description or brainstorming subject)
2. Invoke `wiki-query` on that topic — read index, grep wiki, surface matching pages
3. Present findings concisely: 2–5 bullets with `[[wiki-link]]` citations
4. If wiki has nothing relevant: say so in one line, no padding
5. Return control — the debugging/brainstorming skill continues normally

## Skill: `wiki-after`

### Trigger description

> "Invoke when systematic-debugging resolves (root cause confirmed, fix verified) or when brainstorming produces an approved spec. Evaluates whether findings are wiki-worthy and files them via wiki-ingest if so."

### Behavior

1. Collect findings: root cause + fix (debugging) or key design decisions (brainstorming)
2. Apply judgment gate — proceed to ingest only if **all** are true:
   - Finding is non-obvious (not a trivial typo or syntax error)
   - Finding is cross-project reusable (not tied to one repo's internals)
   - Finding is not already well-covered in the wiki (use `wiki-before` result as signal)
3. If gate passes: invoke `wiki-ingest` with the finding as a synthetic note
4. If gate fails: end silently — no "I decided not to file this" message

### Judgment examples

| Finding | Ingest? |
|---|---|
| Vercel Fluid Compute keeps instances warm across concurrent requests | Yes — vendor behavior, cross-project |
| Forgot to add `await` before async call in `UserService.ts` | No — project-specific, trivial |
| Design decision: use two micro-skills instead of one for cleaner triggers | Yes — architectural pattern, reusable reasoning |
| Fixed wrong variable name in `auth.py` | No — project-specific bug |
| Next.js App Router caches `fetch()` by default, breaking real-time data | Yes — framework quirk, non-obvious |

## Integration Constraints

- Both skills use **absolute paths** to the wiki (`/Users/adrianbadarau/code/llm-wiki`) — same as existing wiki skills
- `wiki-before` and `wiki-after` are **read-through / write-through wrappers** — they delegate to `wiki-query` and `wiki-ingest` respectively; they do not re-implement wiki logic
- The superpowers plugin files (`~/.claude/plugins/cache/...`) are **not modified** — integration is entirely in the new skills
- Silent on negative judgment — automatic mode must not interrupt workflow with "I chose not to save this"

## Out of Scope

- Integration with other superpowers skills (TDD, verification, etc.) — can be added later by expanding `wiki-before`/`wiki-after` descriptions
- Modifying `wiki-query` or `wiki-ingest` core logic
- Any changes to the superpowers plugin
