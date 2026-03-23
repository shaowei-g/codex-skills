#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
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
EOF
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

bash "$script_dir/validate_subagent_response.sh" \
  --file "$response_file" \
  --feature "$feature" \
  --assigned-phase "$assigned_phase" \
  --assigned-subagent "$assigned_subagent"

eval "$(
  python3 - "$response_file" <<'PY'
import pathlib
import re
import shlex
import sys

path = pathlib.Path(sys.argv[1])
text = path.read_text(encoding="utf-8")

def first_bullet(heading: str) -> str:
    pattern = re.compile(rf'^{re.escape(heading)}\n((?:- .*\n?)*)', re.M)
    m = pattern.search(text)
    if not m:
        return ""
    for line in m.group(1).splitlines():
        if line.startswith("- "):
            return line[2:].strip()
    return ""

def q(v: str) -> str:
    return shlex.quote(v)

status = first_bullet("Status:")
next_phase = first_bullet("Recommended-Next-Phase:")
next_subagent = first_bullet("Recommended-Next-Subagent:")

print(f"DELEGATED_STATUS={q(status)}")
print(f"RECOMMENDED_NEXT_PHASE={q(next_phase)}")
print(f"RECOMMENDED_NEXT_SUBAGENT={q(next_subagent)}")
PY
)"

response_sha256="$(
  python3 - "$response_file" <<'PY'
import hashlib
import pathlib
import sys
p = pathlib.Path(sys.argv[1])
print("sha256:" + hashlib.sha256(p.read_bytes()).hexdigest())
PY
)"

marker_validation_mode="skipped"
marker_validation_passed="true"
authoritative_basis=""

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
    printf 'VALIDATION_STATUS=%q\n' "accepted_without_snapshot"
    printf 'VALIDATION_REASON=%q\n' "phase not cached by routing snapshot v1"
    exit 0
    ;;
esac

if [[ "$DELEGATED_STATUS" != "completed" ]]; then
  printf 'VALIDATION_STATUS=%q\n' "accepted_without_snapshot"
  printf 'VALIDATION_REASON=%q\n' "delegated status is not completed"
  exit 0
fi

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
  --response-sha256 "$response_sha256"
  --response-schema-valid true
  --marker-validation-mode "$marker_validation_mode"
  --marker-validation-passed "$marker_validation_passed"
)

if [[ -n "$snapshot_file" ]]; then
  write_args+=(--snapshot-file "$snapshot_file")
fi

bash "$script_dir/read_or_refresh_routing_snapshot.sh" "${write_args[@]}"
