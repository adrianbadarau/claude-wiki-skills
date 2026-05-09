---
name: wiki-after
description: Invoke when systematic-debugging resolves (root cause confirmed, fix verified) or when brainstorming produces an approved spec. Evaluates whether findings are wiki-worthy and files them via wiki-ingest if so.
---

# wiki-after

## Overview

Evaluates session findings and files them to the wiki if they meet the reusability bar. Delegates entirely to `wiki-ingest` — does not implement its own wiki writing logic.

**Core principle:** only file what will be useful across projects. Trivial fixes and project-specific details pollute the wiki; non-obvious, reusable insights compound it.

## When to Use

Triggers:
- `systematic-debugging` has completed: root cause identified, fix implemented, fix verified
- `brainstorming` has completed: spec written and approved by user

Do NOT use for:
- Mid-session (only fires at terminal state — root cause confirmed OR spec approved, not before)
- When the user explicitly says "don't save this"

## Hook Integration

Claude Code can auto-select this skill from the description. Codex Desktop/CLI plugin installs also inject a `Stop` reminder from `hooks/hooks.json`, so the skill is considered after a debugging or brainstorming workflow reaches its terminal state.

The hook is only a reminder. Still apply the judgment gate below and stay silent when it fails.

## Judgment Gate

Before invoking `wiki-ingest`, apply this gate. Proceed **only if all three are true:**

1. **Non-obvious** — Would a competent developer reading the error message or design brief have derived this immediately? If yes, skip. If no (required non-obvious investigation, a surprise, a gotcha), proceed.

2. **Cross-project reusable** — Is this finding tied to one specific repository's internals, or would it be useful in a different project? If project-specific, skip. If cross-project (a vendor behavior, a framework quirk, an architectural pattern, a library gotcha), proceed.

3. **Not already well-covered in the wiki** — Use the `wiki-before` result from this same session as a signal. If the wiki already has a high-confidence page on this exact finding, skip (unless the session adds materially new information). If the wiki had nothing or only partial coverage, proceed.

**If the gate fails: end silently.** Do not tell the user "I decided not to save this." Automatic mode must not interrupt workflow with negative decisions.

## Judgment Examples

| Finding | Ingest? | Reason |
|---|---|---|
| Vercel Fluid Compute keeps instances warm across concurrent requests | Yes | Vendor behavior, cross-project, non-obvious |
| Forgot `await` before async call in `UserService.ts` | No | Project-specific, trivial |
| Design: two micro-skills instead of one for cleaner trigger separation | Yes | Architectural pattern, reusable reasoning |
| Fixed wrong variable name in `auth.py` | No | Project-specific bug |
| Next.js App Router caches `fetch()` by default, breaks real-time data | Yes | Framework quirk, non-obvious, cross-project |
| Pytest `tmp_path` fixture creates a fresh dir per test, not per session | Yes | Framework behavior, non-obvious to newcomers |
| Missing import in `routes.py` | No | Trivial, project-specific |

## Workflow

1. **Collect findings:**
   - For `systematic-debugging`: the root cause, the fix, and the non-obvious element that required investigation.
   - For `brainstorming`: the key design decisions, the approach chosen, and the rationale.

2. **Apply the judgment gate** (all three criteria above).

3. **If gate passes:** invoke the `wiki-ingest` skill. Pass the finding as a synthetic note — a concise summary of what was learned, why it's non-obvious, and what the fix or decision was. Do not re-implement ingest logic here; let `wiki-ingest` handle file placement, frontmatter, index, and log.

4. **If gate fails:** end. No message to the user.

## Cross-Project Usage

This skill fires from any working directory. The wiki path is absolute — `wiki-ingest` handles this. Do not resolve paths relative to cwd.

## Common Mistakes

- **Auto-ingesting everything.** The gate exists to prevent wiki pollution. Apply it strictly.
- **Telling the user when the gate fails.** Silence is correct behavior on negative judgment.
- **Firing before the terminal state.** Do not invoke during debugging (e.g., after Phase 2 but before Phase 4 completes). Wait for root cause confirmed + fix verified.
- **Re-implementing wiki write logic.** Delegate entirely to `wiki-ingest`. This skill only judges and hands off.
