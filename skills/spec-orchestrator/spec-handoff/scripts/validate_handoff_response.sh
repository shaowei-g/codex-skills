#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  validate_handoff_response.sh [--file <path>]

Validate that a handoff response contains all required schema headings in the
exact order expected by spec-handoff. If no file is provided, stdin is used.
EOF
}

extract_section_value() {
  local heading=$1
  local file=$2

  awk -v heading="$heading" '
    $0 == heading { in_section = 1; next }
    in_section && /^[A-Za-z][A-Za-z -]*:$/ { exit }
    in_section { print }
  ' "$file"
}

extract_first_bullet_value() {
  local heading=$1
  local file=$2
  local line

  while IFS= read -r line; do
    if [[ $line =~ ^-[[:space:]]*(.+)$ ]]; then
      printf '%s\n' "${BASH_REMATCH[1]}"
      return 0
    fi
  done < <(extract_section_value "$heading" "$file")
}

require_enum_value() {
  local heading=$1
  local value=$2
  shift 2
  local allowed

  for allowed in "$@"; do
    if [[ "$value" == "$allowed" ]]; then
      return 0
    fi
  done

  echo "Invalid value for $heading: $value" >&2
  exit 1
}

require_nonempty_value() {
  local heading=$1
  local value=$2

  if [[ -z "${value//[[:space:]]/}" ]]; then
    echo "Missing value for $heading" >&2
    exit 1
  fi
}

input_file=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --file)
      input_file=${2-}
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

tmp_file=""
cleanup() {
  if [[ -n "$tmp_file" && -f "$tmp_file" ]]; then
    rm -f "$tmp_file"
  fi
}
trap cleanup EXIT

if [[ -n "$input_file" ]]; then
  if [[ ! -f "$input_file" ]]; then
    echo "Response file not found: $input_file" >&2
    exit 1
  fi
  source_file=$input_file
else
  tmp_file=$(mktemp)
  cat > "$tmp_file"
  source_file=$tmp_file
fi

mapfile -t actual_headings < <(grep -E '^[A-Za-z][A-Za-z -]*:$' "$source_file")
expected_headings=(
  "Status:"
  "Feature-Slug:"
  "Assigned-Phase:"
  "Assigned-Subagent:"
  "Scope:"
  "Summary:"
  "Files-Changed:"
  "Files-Read:"
  "Missing-Prerequisites:"
  "Contract-Violations:"
  "Blockers:"
  "Unresolved Questions:"
  "Drift:"
  "Evidence:"
  "Recommended-Next-Phase:"
  "Recommended-Next-Subagent:"
  "Notes:"
  "Self-Check:"
)

if [[ ${#actual_headings[@]} -ne ${#expected_headings[@]} ]]; then
  echo "Invalid heading count: expected ${#expected_headings[@]}, got ${#actual_headings[@]}" >&2
  exit 1
fi

for index in "${!expected_headings[@]}"; do
  if [[ "${actual_headings[$index]}" != "${expected_headings[$index]}" ]]; then
    echo "Heading order mismatch at position $((index + 1)): expected '${expected_headings[$index]}', got '${actual_headings[$index]}'" >&2
    exit 1
  fi
done

required_self_check=(
  "- one_bounded_scope = true"
  "- assigned_phase_only = true"
  "- chose_next_phase = false"
  "- chose_next_subagent = false"
  "- unauthorized_handoff = false"
  "- outside_ownership_modification = false"
  "- required_response_schema_used = true"
  "- terminating_now = true"
)

for line in "${required_self_check[@]}"; do
  if ! grep -Fqx -- "$line" "$source_file"; then
    echo "Missing self-check line: $line" >&2
    exit 1
  fi
done

status=$(extract_first_bullet_value "Status:" "$source_file")
feature_slug=$(extract_first_bullet_value "Feature-Slug:" "$source_file")
assigned_phase=$(extract_first_bullet_value "Assigned-Phase:" "$source_file")
assigned_subagent=$(extract_first_bullet_value "Assigned-Subagent:" "$source_file")
scope=$(extract_first_bullet_value "Scope:" "$source_file")
recommended_next_phase=$(extract_first_bullet_value "Recommended-Next-Phase:" "$source_file")
recommended_next_subagent=$(extract_first_bullet_value "Recommended-Next-Subagent:" "$source_file")

require_nonempty_value "Status:" "$status"
require_nonempty_value "Feature-Slug:" "$feature_slug"
require_nonempty_value "Assigned-Phase:" "$assigned_phase"
require_nonempty_value "Assigned-Subagent:" "$assigned_subagent"
require_nonempty_value "Scope:" "$scope"
require_nonempty_value "Recommended-Next-Phase:" "$recommended_next_phase"
require_nonempty_value "Recommended-Next-Subagent:" "$recommended_next_subagent"

if ! [[ "$feature_slug" =~ ^[A-Za-z0-9._-]+$ ]]; then
  echo "Invalid Feature-Slug: $feature_slug" >&2
  exit 1
fi

require_enum_value "Status:" "$status" completed blocked rejected
require_enum_value "Assigned-Phase:" "$assigned_phase" inspection specification planning "task decomposition" implementation verification "drift check" handoff
require_enum_value "Assigned-Subagent:" "$assigned_subagent" spec-handoff
require_enum_value "Recommended-Next-Phase:" "$recommended_next_phase" inspection specification planning "task decomposition" implementation verification "drift check" handoff none
require_enum_value "Recommended-Next-Subagent:" "$recommended_next_subagent" spec-analyst spec-planner spec-tasker spec-implementer spec-verifier spec-drift-check spec-handoff none

echo "handoff response schema is valid"