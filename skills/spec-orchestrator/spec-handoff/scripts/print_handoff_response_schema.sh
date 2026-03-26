#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  print_handoff_response_schema.sh --status <completed|blocked|rejected>

Print the handoff status-only response template.
EOF
}

status=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --status) status=${2-}; shift 2 ;;
    --feature|--scope|--result|--artifacts|--recommended-next-phase|--recommended-next-subagent)
      # Accepted for backward compatibility but ignored by the status-only schema.
      shift 2
      ;;
    --help|-h) usage; exit 0 ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

[[ -n "$status" ]] || { echo "Missing required argument: --status" >&2; usage >&2; exit 1; }

case "$status" in
  completed|blocked|rejected) ;;
  *)
    echo "Invalid --status: $status" >&2
    exit 1
    ;;
esac

printf 'Status:\n\n- %s\n' "$status"
