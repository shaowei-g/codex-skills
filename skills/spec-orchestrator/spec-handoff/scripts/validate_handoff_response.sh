\
#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  validate_handoff_response.sh [--file <path>]

Validate that a handoff response contains all required compact schema headings in the
exact order expected by spec-handoff. If no file is provided, stdin is used.
EOF
}

input_file=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --file) input_file=${2-}; shift 2 ;;
    --help|-h) usage; exit 0 ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
shared_validator="$script_dir/../../scripts/validate_subagent_response.sh"

if [[ -n "$input_file" ]]; then
  bash "$shared_validator" --file "$input_file" --assigned-phase handoff --assigned-subagent spec-handoff
else
  tmp_file=$(mktemp)
  trap 'rm -f "$tmp_file"' EXIT
  cat > "$tmp_file"
  bash "$shared_validator" --file "$tmp_file" --assigned-phase handoff --assigned-subagent spec-handoff
fi
