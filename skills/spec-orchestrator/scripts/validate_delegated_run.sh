#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
Usage:
  bash ./skills/spec-orchestrator/scripts/validate_delegated_run.sh \
    --repo-root /abs/path/to/repo \
    --feature <feature-slug> \
    --response-file /abs/path/to/response.md \
    --assigned-phase <phase> \
    --assigned-subagent <subagent> \
    [--marker-path /abs/path/to/repo/specs/<feature>] \
    [--snapshot-file /abs/path/to/routing-snapshot.json]

Rules:
- Always validates subagent response schema.
- Runs artifact marker validation for:
  specification, planning, task decomposition
- Writes routing snapshot only when:
  - response status is completed
  - schema is valid
  - marker validation passes when required
- Treats this script as the single snapshot-refresh entry point for accepted delegated runs.
- Verifies the snapshot by rereading it after refresh and fails loudly on mismatch.
USAGE
}

select_python() {
  if command -v python3 >/dev/null 2>&1; then
    printf '%s\n' python3
    return 0
  fi
  if command -v python >/dev/null 2>&1; then
    printf '%s\n' python
    return 0
  fi
  echo "python runtime not found (need python3 or python)" >&2
  exit 127
}

repo_root=""
feature=""
response_file=""
assigned_phase=""
assigned_subagent=""
marker_path=""
snapshot_file=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo-root) repo_root="${2-}"; shift 2 ;;
    --feature) feature="${2-}"; shift 2 ;;
    --response-file) response_file="${2-}"; shift 2 ;;
    --assigned-phase) assigned_phase="${2-}"; shift 2 ;;
    --assigned-subagent) assigned_subagent="${2-}"; shift 2 ;;
    --marker-path) marker_path="${2-}"; shift 2 ;;
    --snapshot-file) snapshot_file="${2-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 2
      ;;
  esac
done

[[ -n "$repo_root" && -n "$feature" && -n "$response_file" && -n "$assigned_phase" && -n "$assigned_subagent" ]] || {
  usage
  exit 2
}

[[ -d "$repo_root" ]] || { echo "repo root not found: $repo_root" >&2; exit 2; }
[[ -f "$response_file" ]] || { echo "response file not found: $response_file" >&2; exit 2; }

if [[ -z "$marker_path" ]]; then
  marker_path="$repo_root/specs/$feature"
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
python_bin="$(select_python)"

eval "$(
  bash "$script_dir/compute_feature_fingerprint.sh" \
    --repo-root "$repo_root" \
    --feature "$feature"
)"

bash "$script_dir/validate_subagent_response.sh" \
  --file "$response_file" \
  --feature "$feature" \
  --assigned-phase "$assigned_phase" \
  --assigned-subagent "$assigned_subagent"

eval "$(
  "$python_bin" - "$response_file" <<'PY'
import hashlib
import pathlib
import shlex
import sys

path = pathlib.Path(sys.argv[1])
lines = path.read_text(encoding="utf-8").splitlines()
headings = {}
current_heading = None
buffer = []

for line in lines:
    stripped = line.strip()
    if stripped.endswith(":") and stripped[:-1] and all(ch.isalpha() or ch in " -" for ch in stripped[:-1]):
        if current_heading is not None:
            headings[current_heading] = list(buffer)
        current_heading = stripped
        buffer = []
        continue
    if current_heading is not None:
        buffer.append(line)

if current_heading is not None:
    headings[current_heading] = list(buffer)

def first_value(heading):
    section = headings.get(heading, [])
    for raw in section:
        stripped = raw.strip()
        if not stripped:
            continue
        if stripped.startswith("- "):
            return stripped[2:].strip()
        return stripped
    return ""

def q(value):
    return shlex.quote(value)

response_sha = "sha256:" + hashlib.sha256(path.read_bytes()).hexdigest()
status = first_value("Status:")
next_phase = first_value("Recommended-Next-Phase:")
next_subagent = first_value("Recommended-Next-Subagent:")

print(f"DELEGATED_STATUS={q(status)}")
print(f"RECOMMENDED_NEXT_PHASE={q(next_phase)}")
print(f"RECOMMENDED_NEXT_SUBAGENT={q(next_subagent)}")
print(f"RESPONSE_SHA256={q(response_sha)}")
PY
)"

marker_validation_mode="skipped"
marker_validation_passed="true"
authoritative_basis=""
cacheable_phase="true"

case "$assigned_phase" in
  inspection)
    authoritative_basis="validated_inspection"
    ;;
  specification|planning|"task decomposition")
    bash "$script_dir/validate_artifact_markers.sh" --require-markers "$marker_path"
    marker_validation_mode="required"
    marker_validation_passed="true"
    authoritative_basis="validated_markers"
    ;;
  *)
    cacheable_phase="false"
    ;;
esac

if [[ "$cacheable_phase" != "true" ]]; then
  printf 'VALIDATION_STATUS=%q\n' "accepted_without_snapshot"
  printf 'VALIDATION_REASON=%q\n' "phase not cached by routing snapshot v1"
  printf 'DELEGATED_STATUS=%q\n' "$DELEGATED_STATUS"
  printf 'RECOMMENDED_NEXT_PHASE=%q\n' "$RECOMMENDED_NEXT_PHASE"
  printf 'RECOMMENDED_NEXT_SUBAGENT=%q\n' "$RECOMMENDED_NEXT_SUBAGENT"
  exit 0
fi

if [[ "$DELEGATED_STATUS" != "completed" ]]; then
  printf 'VALIDATION_STATUS=%q\n' "accepted_without_snapshot"
  printf 'VALIDATION_REASON=%q\n' "delegated status is not completed"
  printf 'DELEGATED_STATUS=%q\n' "$DELEGATED_STATUS"
  printf 'RECOMMENDED_NEXT_PHASE=%q\n' "$RECOMMENDED_NEXT_PHASE"
  printf 'RECOMMENDED_NEXT_SUBAGENT=%q\n' "$RECOMMENDED_NEXT_SUBAGENT"
  exit 0
fi

export FEATURE_FINGERPRINT FINGERPRINT_INPUT_COUNT ARTIFACTS_JSON

write_args=(
  --mode write
  --repo-root "$repo_root"
  --feature "$feature"
  --authoritative-basis "$authoritative_basis"
  --phase-just-validated "$assigned_phase"
  --earliest-unresolved-phase "$RECOMMENDED_NEXT_PHASE"
  --recommended-next-phase "$RECOMMENDED_NEXT_PHASE"
  --recommended-next-subagent "$RECOMMENDED_NEXT_SUBAGENT"
  --response-file "$response_file"
  --response-sha256 "$RESPONSE_SHA256"
  --response-schema-valid true
  --marker-validation-mode "$marker_validation_mode"
  --marker-validation-passed "$marker_validation_passed"
  --skip-fingerprint-recompute true
)
if [[ -n "$snapshot_file" ]]; then
  write_args+=(--snapshot-file "$snapshot_file")
fi

eval "$(bash "$script_dir/read_or_refresh_routing_snapshot.sh" "${write_args[@]}")"
write_snapshot_status="$SNAPSHOT_STATUS"
write_snapshot_file="$SNAPSHOT_FILE"
write_snapshot_sha="$SNAPSHOT_SHA256"
write_feature_fingerprint="$FEATURE_FINGERPRINT"
write_phase="$EARLIEST_UNRESOLVED_PHASE"
write_subagent="$RECOMMENDED_NEXT_SUBAGENT"
expected_next_phase="$RECOMMENDED_NEXT_PHASE"
expected_next_subagent="$RECOMMENDED_NEXT_SUBAGENT"
expected_response_sha="$RESPONSE_SHA256"

lookup_args=(
  --mode lookup
  --repo-root "$repo_root"
  --feature "$feature"
)
if [[ -n "$snapshot_file" ]]; then
  lookup_args+=(--snapshot-file "$snapshot_file")
fi

eval "$(bash "$script_dir/read_or_refresh_routing_snapshot.sh" "${lookup_args[@]}")"

if [[ "$write_snapshot_status" != "written" ]]; then
  echo "snapshot refresh verification failed: write status '$write_snapshot_status'" >&2
  exit 1
fi
if [[ "$SNAPSHOT_STATUS" != "hit" ]]; then
  echo "snapshot refresh verification failed: lookup status '$SNAPSHOT_STATUS'" >&2
  exit 1
fi
if [[ "${EARLIEST_UNRESOLVED_PHASE:-}" != "$expected_next_phase" ]]; then
  echo "snapshot refresh verification failed: lookup earliest unresolved phase '$EARLIEST_UNRESOLVED_PHASE' does not match '$expected_next_phase'" >&2
  exit 1
fi
if [[ "${RECOMMENDED_NEXT_PHASE:-}" != "$expected_next_phase" ]]; then
  echo "snapshot refresh verification failed: lookup recommended next phase '$RECOMMENDED_NEXT_PHASE' does not match '$expected_next_phase'" >&2
  exit 1
fi
if [[ "${RECOMMENDED_NEXT_SUBAGENT:-}" != "$expected_next_subagent" ]]; then
  echo "snapshot refresh verification failed: lookup next subagent '$RECOMMENDED_NEXT_SUBAGENT' does not match '$expected_next_subagent'" >&2
  exit 1
fi
if [[ "${SNAPSHOT_FEATURE_FINGERPRINT:-}" != "$write_feature_fingerprint" ]]; then
  echo "snapshot refresh verification failed: snapshot fingerprint '$SNAPSHOT_FEATURE_FINGERPRINT' does not match '$write_feature_fingerprint'" >&2
  exit 1
fi
if [[ "${SNAPSHOT_RESPONSE_SHA256:-}" != "$expected_response_sha" ]]; then
  echo "snapshot refresh verification failed: snapshot response sha '$SNAPSHOT_RESPONSE_SHA256' does not match '$expected_response_sha'" >&2
  exit 1
fi

printf 'VALIDATION_STATUS=%q\n' "accepted_with_snapshot"
printf 'VALIDATION_REASON=%q\n' "schema valid and snapshot refreshed"
printf 'DELEGATED_STATUS=%q\n' "$DELEGATED_STATUS"
printf 'RECOMMENDED_NEXT_PHASE=%q\n' "$expected_next_phase"
printf 'RECOMMENDED_NEXT_SUBAGENT=%q\n' "$expected_next_subagent"
printf 'SNAPSHOT_STATUS=%q\n' "verified"
printf 'SNAPSHOT_WRITE_STATUS=%q\n' "$write_snapshot_status"
printf 'SNAPSHOT_LOOKUP_STATUS=%q\n' "$SNAPSHOT_STATUS"
printf 'SNAPSHOT_FILE=%q\n' "$write_snapshot_file"
printf 'SNAPSHOT_SHA256=%q\n' "$write_snapshot_sha"
printf 'SNAPSHOT_WRITE_PHASE=%q\n' "$write_phase"
printf 'SNAPSHOT_WRITE_SUBAGENT=%q\n' "$write_subagent"
printf 'SNAPSHOT_LOOKUP_PHASE=%q\n' "$EARLIEST_UNRESOLVED_PHASE"
printf 'SNAPSHOT_LOOKUP_SUBAGENT=%q\n' "$RECOMMENDED_NEXT_SUBAGENT"
printf 'RESPONSE_SHA256=%q\n' "$expected_response_sha"
