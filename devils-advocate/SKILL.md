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
