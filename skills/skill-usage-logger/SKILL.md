---
name: skill-usage-logger
description: All skill MUST use this logger to record usage events in NDJSON format.Log Codex skill usage events to NDJSON with safe concurrent appends.
---

# Skill Usage Logger

## Overview

Provide a single logger script that any skill can call to append an NDJSON event to `~/.codex/skill-usage.ndjson`, with concurrency-safe writes.

## Quick Start

1. Add a small logging note at the very top of a skill's `SKILL.md` so it is executed whenever that skill runs.
2. Call the logger once after successful completion, or immediately before aborting on error.

Use this snippet (edit `<skill_name>` and optional `<meta_json>`):

```bash
# Usage logging (call on success or error as appropriate)
~/.codex/skills/skill-usage-logger/scripts/log_skill_usage.sh \
  --skill "<skill_name>" \
  --status "success" \
  --meta '<meta_json>'
```

If an error prevents completion, call with `--status error` and include useful `--meta` (e.g., reason or failing step).

## Logger Script

- Path: `~/.codex/skills/skill-usage-logger/scripts/log_skill_usage.sh`
- Required args:
  - `--skill <skill_name>`
  - `--status <success|error>`
- Optional args:
  - `--meta <json_string>` (must be valid JSON; included as `meta` in the event)

### Output format (NDJSON)

Each call appends one line with at least:

```json
{ "ts": "<ISO8601>", "skill": "<skill_name>", "status": "success|error" }
```

When `--meta` is provided and valid JSON, it is included as `"meta": <json_value>`.

## Concurrency Notes

The script uses `flock` on `~/.codex/skill-usage.ndjson.lock` to prevent interleaving when multiple skills log at the same time.

## Example

```bash
~/.codex/skills/skill-usage-logger/scripts/log_skill_usage.sh \
  --skill "frontend-design" \
  --status "success" \
  --meta '{"project":"landing-page","durationMs":1842}'
```

## Resources

### scripts/

- `log_skill_usage.sh`: NDJSON logger with required parameters and concurrency-safe appends.
