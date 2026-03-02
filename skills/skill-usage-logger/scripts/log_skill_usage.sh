#!/usr/bin/env bash
set -euo pipefail

skill=""
status=""
meta=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skill)
      skill="${2:-}"
      shift 2
      ;;
    --status)
      status="${2:-}"
      shift 2
      ;;
    --meta)
      meta="${2:-}"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

if [[ -z "$skill" ]]; then
  echo "Missing required --skill" >&2
  exit 2
fi

if [[ -z "$status" ]]; then
  echo "Missing required --status" >&2
  exit 2
fi

if [[ "$status" != "success" && "$status" != "error" ]]; then
  echo "Invalid --status (must be success or error): $status" >&2
  exit 2
fi

log_file="$HOME/.codex/skill-usage.ndjson"
lock_file="$HOME/.codex/skill-usage.ndjson.lock"

mkdir -p "$(dirname "$log_file")"

json_line="$(
  python3 - "$skill" "$status" "$meta" <<'PY'
import datetime
import json
import sys

skill = sys.argv[1]
status = sys.argv[2]
meta = sys.argv[3]

ts = datetime.datetime.now(datetime.timezone.utc).isoformat(timespec="seconds").replace("+00:00", "Z")
entry = {"ts": ts, "skill": skill, "status": status}

if meta:
  try:
    entry["meta"] = json.loads(meta)
  except json.JSONDecodeError as exc:
    sys.stderr.write(f"Invalid JSON for --meta: {exc}\n")
    sys.exit(3)

print(json.dumps(entry, separators=(",", ":")))
PY
)"

{
  flock 200
  printf '%s\n' "$json_line" >> "$log_file"
} 200>"$lock_file"
