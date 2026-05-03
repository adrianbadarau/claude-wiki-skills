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
