#!/usr/bin/env bash
set -euo pipefail

event_type=""
conflict_type=""
source=""
name=""
message=""
meta=""
lock_timeout="10"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --event-type)
      event_type="${2:-}"
      shift 2
      ;;
    --conflict-type)
      conflict_type="${2:-}"
      shift 2
      ;;
    --source)
      source="${2:-}"
      shift 2
      ;;
    --name)
      name="${2:-}"
      shift 2
      ;;
    --message)
      message="${2:-}"
      shift 2
      ;;
    --meta)
      meta="${2:-}"
      shift 2
      ;;
    --lock-timeout)
      lock_timeout="${2:-}"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

if [[ -z "$event_type" ]]; then
  echo "Missing required --event-type" >&2
  exit 2
fi

case "$event_type" in
  error|conflict|warning|info)
    ;;
  *)
    echo "Invalid --event-type (must be error|conflict|warning|info): $event_type" >&2
    exit 2
    ;;
esac

if [[ "$event_type" == "conflict" && -z "$conflict_type" ]]; then
  echo "Missing required --conflict-type when --event-type conflict" >&2
  exit 2
fi

if ! [[ "$lock_timeout" =~ ^[0-9]+$ ]]; then
  echo "Invalid --lock-timeout (must be integer seconds): $lock_timeout" >&2
  exit 2
fi

log_file="$HOME/.codex/diag-events.ndjson"
lock_file="$HOME/.codex/diag-events.ndjson.lock"

mkdir -p "$(dirname "$log_file")"

build_json_line() {
  python3 - "$event_type" "$conflict_type" "$source" "$name" "$message" "$meta" <<'PY'
import datetime
import json
import sys

event_type = sys.argv[1]
conflict_type = sys.argv[2]
source = sys.argv[3]
name = sys.argv[4]
message = sys.argv[5]
meta = sys.argv[6]

ts = datetime.datetime.now(datetime.timezone.utc).isoformat(timespec="seconds").replace("+00:00", "Z")
entry = {"ts": ts, "event_type": event_type}

if conflict_type:
  entry["conflict_type"] = conflict_type
if source:
  entry["source"] = source
if name:
  entry["name"] = name
if message:
  entry["message"] = message

if meta:
  try:
    entry["meta"] = json.loads(meta)
  except json.JSONDecodeError as exc:
    sys.stderr.write(f"Invalid JSON for --meta: {exc}\n")
    sys.exit(3)

print(json.dumps(entry, separators=(",", ":")))
PY
}

append_line() {
  local line
  line="$(build_json_line)"
  printf '%s\n' "$line" >> "$log_file"
}

append_timeout_event_best_effort() {
  local saved_event_type saved_conflict_type saved_message
  saved_event_type="$event_type"
  saved_conflict_type="$conflict_type"
  saved_message="$message"

  event_type="conflict"
  conflict_type="lock_timeout"
  message="lock timeout after ${lock_timeout}s"

  local line
  line="$(build_json_line)"
  printf '%s\n' "$line" >> "$log_file"

  event_type="$saved_event_type"
  conflict_type="$saved_conflict_type"
  message="$saved_message"
}

if command -v flock >/dev/null 2>&1; then
  {
    if ! flock -w "$lock_timeout" 200; then
      append_timeout_event_best_effort
      exit 1
    fi
    append_line
  } 200>"$lock_file"
  exit 0
fi

# Fallback lock: create lock file with O_EXCL.
start_epoch="$(date +%s)"
while true; do
  if python3 - "$lock_file" <<'PY'
import os
import sys

path = sys.argv[1]
try:
  fd = os.open(path, os.O_CREAT | os.O_EXCL | os.O_WRONLY, 0o600)
  with os.fdopen(fd, "w") as f:
    f.write(str(os.getpid()))
  sys.exit(0)
except FileExistsError:
  sys.exit(1)
PY
  then
    append_line
    rm -f "$lock_file"
    exit 0
  fi

  now_epoch="$(date +%s)"
  if (( now_epoch - start_epoch >= lock_timeout )); then
    append_timeout_event_best_effort
    exit 1
  fi

  sleep 0.1
done
