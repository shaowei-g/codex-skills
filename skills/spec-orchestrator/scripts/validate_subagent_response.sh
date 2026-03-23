\
#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  validate_subagent_response.sh [--file <path>] [--feature <slug>] [--assigned-phase <phase>] [--assigned-subagent <name>] [--scope <text>]

Validate that a subagent response conforms to the shared spec-orchestrator
compact response contract. If no file is provided, stdin is used.
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

require_exact_match() {
  local label=$1
  local actual=$2
  local expected=$3
  if [[ -n "$expected" && "$actual" != "$expected" ]]; then
    echo "$label mismatch: expected '$expected', got '$actual'" >&2
    exit 1
  fi
}

validate_artifacts_section() {
  local status="$1"
  local file="$2"
  local python_bin=""
  if command -v python3 >/dev/null 2>&1; then
    python_bin=python3
  elif command -v python >/dev/null 2>&1; then
    python_bin=python
  else
    echo "python runtime not found (need python3 or python)" >&2
    exit 127
  fi

  "$python_bin" - "$status" "$file" <<'PY'
import pathlib
import re
import sys

status = sys.argv[1]
path = pathlib.Path(sys.argv[2])
text = path.read_text(encoding="utf-8")

headings = {}
current = None
buffer = []
heading_re = re.compile(r'^[A-Za-z][A-Za-z -]*:$')
for line in text.splitlines():
    stripped = line.strip()
    if heading_re.match(stripped):
        if current is not None:
            headings[current] = "\n".join(buffer).strip("\n")
        current = stripped
        buffer = []
    elif current is not None:
        buffer.append(line)
if current is not None:
    headings[current] = "\n".join(buffer).strip("\n")

section = headings.get("Artifacts:", "").strip()
if not section:
    raise SystemExit("Missing value for Artifacts:")
if section == "- none":
    raise SystemExit(0)

pattern = re.compile(r'^```artifact\s+path="([^"\n]+)"[^\n]*\n(.*?)\n```[ \t]*$', re.MULTILINE | re.DOTALL)
matches = list(pattern.finditer(section))
if not matches:
    raise SystemExit("Artifacts section must be '- none' or one or more valid artifact fenced blocks")

consumed = []
for match in matches:
    rel_path = match.group(1)
    consumed.append(match.span())
    if rel_path.startswith("/"):
        raise SystemExit(f"Artifact path must be repo-relative, got: {rel_path}")
    if ".." in pathlib.PurePosixPath(rel_path).parts:
        raise SystemExit(f"Artifact path must not contain '..': {rel_path}")

residual = section
for start, end in reversed(consumed):
    residual = residual[:start] + residual[end:]
if residual.strip():
    raise SystemExit("Artifacts section must contain only artifact fenced blocks or '- none'")

if status != "completed":
    raise SystemExit("Artifacts payload blocks are allowed only when Status is completed")
PY
}

input_file=""
expected_feature=""
expected_phase=""
expected_subagent=""
expected_scope=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --file) input_file=${2-}; shift 2 ;;
    --feature) expected_feature=${2-}; shift 2 ;;
    --assigned-phase) expected_phase=${2-}; shift 2 ;;
    --assigned-subagent) expected_subagent=${2-}; shift 2 ;;
    --scope) expected_scope=${2-}; shift 2 ;;
    --help|-h) usage; exit 0 ;;
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
  [[ -f "$input_file" ]] || { echo "Response file not found: $input_file" >&2; exit 1; }
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
  "Result:"
  "Artifacts:"
  "Recommended-Next-Phase:"
  "Recommended-Next-Subagent:"
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
  grep -Fqx -- "$line" "$source_file" || { echo "Missing self-check line: $line" >&2; exit 1; }
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

require_enum_value "Status:" "$status" completed blocked rejected
require_enum_value "Assigned-Phase:" "$assigned_phase" inspection specification planning "task decomposition" implementation verification "drift check" handoff
require_enum_value "Assigned-Subagent:" "$assigned_subagent" spec-viewer spec-analyst spec-planner spec-tasker spec-implementer spec-verifier spec-drift-check spec-handoff
require_enum_value "Recommended-Next-Phase:" "$recommended_next_phase" inspection specification planning "task decomposition" implementation verification "drift check" handoff none
require_enum_value "Recommended-Next-Subagent:" "$recommended_next_subagent" spec-viewer spec-analyst spec-planner spec-tasker spec-implementer spec-verifier spec-drift-check spec-handoff none

require_exact_match "Feature-Slug" "$feature_slug" "$expected_feature"
require_exact_match "Assigned-Phase" "$assigned_phase" "$expected_phase"
require_exact_match "Assigned-Subagent" "$assigned_subagent" "$expected_subagent"
require_exact_match "Scope" "$scope" "$expected_scope"

validate_artifacts_section "$status" "$source_file"
