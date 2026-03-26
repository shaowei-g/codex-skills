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
    [--orchestrator-mode standard|booster] \
    [--marker-path /abs/path/to/repo/specs/<feature>] \
    [--snapshot-file /abs/path/to/routing-snapshot.json] \
    [--disable-response-artifact-materialization true|false]

Rules:
- Always validates the status-only subagent response schema.
- Refreshes the routing snapshot only from a schema-valid delegated response.
- Does not require YAML front matter or marker validation.
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
orchestrator_mode=""
marker_path=""
snapshot_file=""
disable_response_artifact_materialization="false"

emit_result() {
  local validation_status="$1"
  local validation_reason="$2"
  local delegated_status="${3-}"
  local recommended_next_phase="${4-}"
  local recommended_next_subagent="${5-}"
  local snapshot_status="${6-}"
  local response_sha="${7-}"
  local marker_mode="${8-}"
  local marker_passed="${9-}"
  local effective_mode="${10-}"
  local artifact_materialization_status="${11-}"
  local artifact_materialization_count="${12-}"

  printf 'VALIDATION_STATUS=%q\n' "$validation_status"
  printf 'VALIDATION_REASON=%q\n' "$validation_reason"
  printf 'ASSIGNED_PHASE=%q\n' "$assigned_phase"
  printf 'ASSIGNED_SUBAGENT=%q\n' "$assigned_subagent"
  printf 'DELEGATED_STATUS=%q\n' "$delegated_status"
  printf 'RECOMMENDED_NEXT_PHASE=%q\n' "$recommended_next_phase"
  printf 'RECOMMENDED_NEXT_SUBAGENT=%q\n' "$recommended_next_subagent"
  printf 'MARKER_VALIDATION_MODE=%q\n' "$marker_mode"
  printf 'MARKER_VALIDATION_PASSED=%q\n' "$marker_passed"
  printf 'ORCHESTRATOR_MODE=%q\n' "$effective_mode"
  printf 'SNAPSHOT_STATUS=%q\n' "$snapshot_status"
  printf 'ARTIFACT_MATERIALIZATION_STATUS=%q\n' "$artifact_materialization_status"
  printf 'ARTIFACT_MATERIALIZATION_COUNT=%q\n' "$artifact_materialization_count"
  printf 'RESPONSE_SHA256=%q\n' "$response_sha"
  printf 'VALIDATION_SUMMARY=%q\n' "mode=${effective_mode:-unspecified} phase=$assigned_phase delegated_status=${delegated_status:-none} validation=$validation_status materialization=${artifact_materialization_status:-none}/${artifact_materialization_count:-0} next_phase=${recommended_next_phase:-none} next_subagent=${recommended_next_subagent:-none} snapshot=${snapshot_status:-none}"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo-root) repo_root="${2-}"; shift 2 ;;
    --feature) feature="${2-}"; shift 2 ;;
    --response-file) response_file="${2-}"; shift 2 ;;
    --assigned-phase) assigned_phase="${2-}"; shift 2 ;;
    --assigned-subagent) assigned_subagent="${2-}"; shift 2 ;;
    --orchestrator-mode) orchestrator_mode="${2-}"; shift 2 ;;
    --marker-path) marker_path="${2-}"; shift 2 ;;
    --snapshot-file) snapshot_file="${2-}"; shift 2 ;;
    --disable-response-artifact-materialization) disable_response_artifact_materialization="${2-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 2
      ;;
  esac
done

[[ -n "$repo_root" && -n "$feature" && -n "$response_file" && -n "$assigned_phase" && -n "$assigned_subagent" ]] || { usage; exit 2; }
[[ -d "$repo_root" ]] || { echo "repo root not found: $repo_root" >&2; exit 2; }
[[ -f "$response_file" ]] || { echo "response file not found: $response_file" >&2; exit 2; }

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
text = path.read_text(encoding="utf-8")
status = ""
capture = False
for line in text.splitlines():
    stripped = line.strip()
    if stripped == "Status:":
        capture = True
        continue
    if capture and stripped.endswith(":") and stripped[:-1]:
        break
    if capture and stripped.startswith("- "):
        status = stripped[2:].strip()
        break

def q(value):
    return shlex.quote(value)

response_sha = "sha256:" + hashlib.sha256(path.read_bytes()).hexdigest()
print(f"DELEGATED_STATUS={q(status)}")
print(f"RECOMMENDED_NEXT_PHASE={q('none')}")
print(f"RECOMMENDED_NEXT_SUBAGENT={q('none')}")
print(f"RESPONSE_SHA256={q(response_sha)}")
PY
)"

artifact_materialization_status="disabled"
artifact_materialization_count="0"
if [[ "${disable_response_artifact_materialization:-false}" != "true" ]]; then
  artifact_materialization_status="not_applicable"
fi

marker_validation_mode="disabled"
marker_validation_passed="true"
authoritative_basis="validated_response"
cacheable_phase="true"

if [[ "$DELEGATED_STATUS" != "completed" ]]; then
  emit_result "accepted_without_snapshot" "delegated status is not completed" "$DELEGATED_STATUS" "$RECOMMENDED_NEXT_PHASE" "$RECOMMENDED_NEXT_SUBAGENT" "skipped" "$RESPONSE_SHA256" "$marker_validation_mode" "$marker_validation_passed" "${orchestrator_mode:-unspecified}" "$artifact_materialization_status" "$artifact_materialization_count"
  exit 0
fi

if [[ "$cacheable_phase" != "true" ]]; then
  emit_result "accepted_without_snapshot" "phase not cached by routing snapshot v1" "$DELEGATED_STATUS" "$RECOMMENDED_NEXT_PHASE" "$RECOMMENDED_NEXT_SUBAGENT" "skipped" "$RESPONSE_SHA256" "$marker_validation_mode" "$marker_validation_passed" "${orchestrator_mode:-unspecified}" "$artifact_materialization_status" "$artifact_materialization_count"
  exit 0
fi

eval "$(
  bash "$script_dir/compute_feature_fingerprint.sh" \
    --repo-root "$repo_root" \
    --feature "$feature"
)"

export FEATURE_FINGERPRINT FINGERPRINT_INPUT_COUNT ARTIFACTS_JSON

write_args=(
  --mode write
  --repo-root "$repo_root"
  --feature "$feature"
  --authoritative-basis "$authoritative_basis"
  --orchestrator-mode "${orchestrator_mode:-unspecified}"
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

lookup_args=(--mode lookup --repo-root "$repo_root" --feature "$feature")
if [[ -n "$snapshot_file" ]]; then
  lookup_args+=(--snapshot-file "$snapshot_file")
fi
eval "$(bash "$script_dir/read_or_refresh_routing_snapshot.sh" "${lookup_args[@]}")"

[[ "$write_snapshot_status" == "written" ]] || { echo "snapshot refresh verification failed: write status '$write_snapshot_status'" >&2; exit 1; }
[[ "$SNAPSHOT_STATUS" == "hit" ]] || { echo "snapshot refresh verification failed: lookup status '$SNAPSHOT_STATUS'" >&2; exit 1; }
[[ "${EARLIEST_UNRESOLVED_PHASE:-}" == "$expected_next_phase" ]] || { echo "snapshot refresh verification failed: lookup earliest unresolved phase '$EARLIEST_UNRESOLVED_PHASE' does not match '$expected_next_phase'" >&2; exit 1; }
[[ "${RECOMMENDED_NEXT_PHASE:-}" == "$expected_next_phase" ]] || { echo "snapshot refresh verification failed: lookup recommended next phase '$RECOMMENDED_NEXT_PHASE' does not match '$expected_next_phase'" >&2; exit 1; }
[[ "${RECOMMENDED_NEXT_SUBAGENT:-}" == "$expected_next_subagent" ]] || { echo "snapshot refresh verification failed: lookup next subagent '$RECOMMENDED_NEXT_SUBAGENT' does not match '$expected_next_subagent'" >&2; exit 1; }
[[ "${SNAPSHOT_FEATURE_FINGERPRINT:-}" == "$write_feature_fingerprint" ]] || { echo "snapshot refresh verification failed: snapshot fingerprint '$SNAPSHOT_FEATURE_FINGERPRINT' does not match '$write_feature_fingerprint'" >&2; exit 1; }
[[ "${SNAPSHOT_RESPONSE_SHA256:-}" == "$expected_response_sha" ]] || { echo "snapshot refresh verification failed: snapshot response sha '$SNAPSHOT_RESPONSE_SHA256' does not match '$expected_response_sha'" >&2; exit 1; }

emit_result "accepted_with_snapshot" "schema valid and snapshot refreshed" "$DELEGATED_STATUS" "$expected_next_phase" "$expected_next_subagent" "verified" "$expected_response_sha" "$marker_validation_mode" "$marker_validation_passed" "${orchestrator_mode:-unspecified}" "$artifact_materialization_status" "$artifact_materialization_count"
printf 'SNAPSHOT_WRITE_STATUS=%q\n' "$write_snapshot_status"
printf 'SNAPSHOT_LOOKUP_STATUS=%q\n' "$SNAPSHOT_STATUS"
printf 'SNAPSHOT_FILE=%q\n' "$write_snapshot_file"
printf 'SNAPSHOT_SHA256=%q\n' "$write_snapshot_sha"
printf 'SNAPSHOT_WRITE_PHASE=%q\n' "$write_phase"
printf 'SNAPSHOT_WRITE_SUBAGENT=%q\n' "$write_subagent"
printf 'SNAPSHOT_LOOKUP_PHASE=%q\n' "$EARLIEST_UNRESOLVED_PHASE"
printf 'SNAPSHOT_LOOKUP_SUBAGENT=%q\n' "$RECOMMENDED_NEXT_SUBAGENT"
