---
name: fetch-url
description: Fetch and read content from user-provided URLs via the MCP `fetch_url` tool, then answer strictly based on the fetched content. Use when a user includes one or more URLs (http/https) and asks for summaries, extraction, comparison, fact-checking, or any analysis of the linked content.
---

# Fetch URL

## Overview

Use this skill to fetch URL content and keep answers grounded in the fetched content rather than prior knowledge or assumptions.

## Workflow

### 1) Identify URLs

- Extract all URLs from the user message.
- If multiple URLs exist, treat each URL as a separate source.

### 2) Fetch content with MCP `fetch_url`

- Always call the MCP tool `fetch_url` for each URL.
- Read the returned content.

### 3) Handle failures

- If `fetch_url` fails for any URL, report the failure clearly.
- Do not guess what the URL contains.
- Ask the user for an alternative (paste the text, provide a different URL, or provide access).

### 4) Answer strictly from fetched content

- Base all analysis strictly on the fetched content.
- If the user asks for details not present in the fetched content, say that the information is not available in the fetched content.
