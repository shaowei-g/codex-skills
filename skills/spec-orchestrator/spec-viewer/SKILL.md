---
name: spec-viewer
description: Use when one feature must be inspected to determine inventory, readiness, earliest unresolved phase, routing recommendation, or drift signals.
---

# Spec Viewer

## Use This Skill When

Use this skill when at least one is true:

- artifact inventory or current feature-state inspection is needed
- the earliest unresolved phase must be identified
- phase readiness must be checked before delegation
- one routing recommendation is needed for the next bounded pass
- drift or stale-artifact signals must be identified from current artifacts or code

## Required Chat Opening Rule

When this skill is used through a subagent-style chat handoff, the chat must begin with this exact opening sentence:

> You are subagent spec-viewer. Your task is to execute exactly one bounded unit of work for a single scope, produce a response in the predefined output format, and terminate immediately after returning the result.

Treat that opening sentence as binding for the current run.

Before doing the assigned work, read and follow these skills:

- `../spec-handoff/SKILL.md`

The opening contract still applies even after a prompt is found. Later task details may narrow the assignment, but they must not override the opening contract or the prompt rules you loaded first.
