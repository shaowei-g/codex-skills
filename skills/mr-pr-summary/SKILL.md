---
name: mr-pr-summary
description: Draft concise, accurate merge request and pull request summaries from a branch diff. Use when the user asks to "create MR summary", "create PR summary", "write merge request description", "summarize this branch", "summarize the diff for review", or wants a paste-ready overview of changes, testing, and notable risks based on the current branch, target branch, commits, and local uncommitted edits.
---

# MR PR Summary

## Overview

Create a paste-ready MR or PR summary grounded in the actual git state, not guesswork. Inspect the current branch, identify the most likely base branch, review the diff and recent commits, then write a short summary that reflects user-facing changes, technical changes, tests, and any important caveats.

## Workflow

### 1. Gather branch context

Start by inspecting the repository state:

- `git branch --show-current`
- `git status --short`
- `git log --oneline --decorate -n 8`

If the user explicitly names a target branch, use that. Otherwise choose the most likely base branch in this order:

1. The merge request target branch if the user provided it.
2. The remote default branch from `git remote show origin`.
3. `main` then `develop`, if origin metadata is unavailable.

State the assumption when the base branch is inferred.

### 2. Inspect the actual changes

Pull both committed and uncommitted context:

- `git diff --stat <base>...HEAD`
- `git diff <base>...HEAD -- <important files if needed>`
- `git diff --stat` for local unstaged changes
- `git diff -- <important locally edited files if needed>`

Read enough high-signal files to understand the feature shape. Prefer page entry points, core hooks/services, API contracts, tests, and configuration changes over exhaustively reading every file.

If the branch contains a very large amount of generated, spec, or support-tooling files, separate them from the product changes in your own notes so the final summary stays readable.

### 3. Distill the branch into user-facing themes

Extract the main change areas:

- New user-facing flows or pages
- API or data-contract changes
- State-management or hook changes
- Infra, provider, or config changes
- Tests added or updated
- Spec, tooling, or internal docs changes

Prefer grouping by outcome, not by file inventory.

### 4. Write the summary

Default to a GitLab/GitHub-friendly structure:

- `Summary`
- `Key changes`
- `Testing`
- `Notes` or `Risks` when needed

Keep it concise and paste-ready. Aim for:

- 1 short paragraph for the overall summary
- 3-7 flat bullets for key changes
- 1 short testing section
- 1 short note section only if it adds signal

### 5. Handle local changes explicitly

If `git status --short` shows local modifications not yet committed, do not ignore them. Either:

- include them in the summary and label them as local or unstaged changes, or
- say the draft covers the committed branch diff and note the extra local files separately

This matters when the user says "create MR summary" while still polishing files locally.

## Output Rules

- Write the final MR/PR summary directly, not an analysis essay.
- Be accurate about what is committed versus only local.
- Avoid listing every file unless the user explicitly asks.
- Mention tests added or updated when present.
- Say if tests or lint were not run.
- Call out meaningful caveats such as authentication blockers, feature flags, schema assumptions, or local-only edits.

## Useful Commands

Use fast, non-interactive commands:

```bash
git branch --show-current
git remote show origin | sed -n '/HEAD branch/s/.*: //p'
git status --short
git log --oneline --decorate -n 8
git diff --stat <base>...HEAD
git diff --stat
```

Then inspect only the most relevant files from the diff.

## Optional MR Editing

If the user asks to update the actual MR or PR page:

- open the page in a browser
- verify authentication first
- edit only after confirming you can access the page
- if blocked by sign-in, say so clearly and stop at that boundary

Do not pretend the remote MR was updated if browser auth is missing.
