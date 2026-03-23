#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
Usage:

Lookup:
  bash ./skills/spec-orchestrator/scripts/read_or_refresh_routing_snapshot.sh \
    --mode lookup \
    --repo-root /abs/path/to/repo \
    --feature <feature-slug>

Write:
  bash ./skills/spec-orchestrator/scripts/read_or_refresh_routing_snapshot.sh \
    --mode write \
    --repo-root /abs/path/to/repo \
    --feature <feature-slug> \
    --authoritative-basis validated_inspection|validated_markers \
    --phase-just-validated <phase> \
    --earliest-unresolved-phase <phase|none> \
    --recommended-next-phase <phase|none> \
    --recommended-next-subagent <subagent|none> \
    --response-file /abs/path/to/response.md \
    --response-sha256 sha256:... \
    --response-schema-valid true|false \
    --marker-validation-mode required|optional|skipped \
    --marker-validation-passed true|false

Optional:
  --snapshot-file /abs/path/to/routing-snapshot.json
  --skip-fingerprint-recompute true|false   # write mode only; default false
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

mode=""
repo_root=""
feature=""
snapshot_file=""
authoritative_basis=""
phase_just_validated=""
earliest_unresolved_phase=""
recommended_next_phase=""
recommended_next_subagent=""
response_file=""
response_sha256=""
response_schema_valid=""
marker_validation_mode=""
marker_validation_passed=""
skip_fingerprint_recompute="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode) mode="${2-}"; shift 2 ;;
    --repo-root) repo_root="${2-}"; shift 2 ;;
    --feature) feature="${2-}"; shift 2 ;;
    --snapshot-file) snapshot_file="${2-}"; shift 2 ;;
    --authoritative-basis) authoritative_basis="${2-}"; shift 2 ;;
    --phase-just-validated) phase_just_validated="${2-}"; shift 2 ;;
    --earliest-unresolved-phase) earliest_unresolved_phase="${2-}"; shift 2 ;;
    --recommended-next-phase) recommended_next_phase="${2-}"; shift 2 ;;
    --recommended-next-subagent) recommended_next_subagent="${2-}"; shift 2 ;;
    --response-file) response_file="${2-}"; shift 2 ;;
    --response-sha256) response_sha256="${2-}"; shift 2 ;;
    --response-schema-valid) response_schema_valid="${2-}"; shift 2 ;;
    --marker-validation-mode) marker_validation_mode="${2-}"; shift 2 ;;
    --marker-validation-passed) marker_validation_passed="${2-}"; shift 2 ;;
    --skip-fingerprint-recompute) skip_fingerprint_recompute="${2-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 2
      ;;
  esac
done

[[ -n "$mode" && -n "$repo_root" && -n "$feature" ]] || { usage; exit 2; }
[[ -d "$repo_root" ]] || { echo "repo root not found: $repo_root" >&2; exit 2; }

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
python_bin="$(select_python)"

if [[ -z "$snapshot_file" ]]; then
  snapshot_file="$repo_root/.codex/spec-orchestrator-state/$feature/routing-snapshot.json"
fi

if [[ "$mode" == "write" && "${skip_fingerprint_recompute,,}" == "true" ]]; then
  : "${FEATURE_FINGERPRINT:?FEATURE_FINGERPRINT must be exported when --skip-fingerprint-recompute true}"
  : "${FINGERPRINT_INPUT_COUNT:?FINGERPRINT_INPUT_COUNT must be exported when --skip-fingerprint-recompute true}"
  : "${ARTIFACTS_JSON:?ARTIFACTS_JSON must be exported when --skip-fingerprint-recompute true}"
else
  eval "$(
    bash "$script_dir/compute_feature_fingerprint.sh" \
      --repo-root "$repo_root" \
      --feature "$feature"
  )"
fi

case "$mode" in
  lookup)
    export SNAPSHOT_FILE="$snapshot_file"
    export FEATURE="$feature"
    export CURRENT_FEATURE_FINGERPRINT="$FEATURE_FINGERPRINT"

    "$python_bin" - <<'PY'
import json
import os
import pathlib
import shlex

snapshot_file = pathlib.Path(os.environ["SNAPSHOT_FILE"])
feature = os.environ["FEATURE"]
current_fingerprint = os.environ["CURRENT_FEATURE_FINGERPRINT"]

def q(value):
    return shlex.quote(value)

def emit(status, reason, payload=None):
    print(f"SNAPSHOT_STATUS={q(status)}")
    print(f"SNAPSHOT_REASON={q(reason)}")
    print(f"SNAPSHOT_FILE={q(str(snapshot_file))}")
    if payload:
        current = payload.get("current", {})
        validation = payload.get("validation", {})
        print(f"SNAPSHOT_FEATURE_FINGERPRINT={q(current.get('feature_fingerprint', ''))}")
        print(f"EARLIEST_UNRESOLVED_PHASE={q(current.get('earliest_unresolved_phase', ''))}")
        print(f"RECOMMENDED_NEXT_PHASE={q(current.get('recommended_next_phase', ''))}")
        print(f"RECOMMENDED_NEXT_SUBAGENT={q(current.get('recommended_next_subagent', ''))}")
        print(f"AUTHORITATIVE_BASIS={q(payload.get('authoritative_basis', ''))}")
        print(f"SNAPSHOT_RESPONSE_SHA256={q(validation.get('response_sha256', ''))}")

if not snapshot_file.exists():
    emit("missing", "snapshot file not found")
    raise SystemExit(0)

try:
    payload = json.loads(snapshot_file.read_text(encoding="utf-8"))
except Exception as exc:
    emit("invalid", f"snapshot parse error: {exc}")
    raise SystemExit(0)

if payload.get("schema_version") != 1:
    emit("invalid", "unsupported schema_version")
    raise SystemExit(0)
if payload.get("snapshot_kind") != "routing":
    emit("invalid", "snapshot_kind must be routing")
    raise SystemExit(0)
if payload.get("feature_slug") != feature:
    emit("invalid", "feature_slug mismatch")
    raise SystemExit(0)

current = payload.get("current", {})
validation = payload.get("validation", {})
snapshot_fingerprint = current.get("feature_fingerprint", "")

if snapshot_fingerprint != current_fingerprint:
    emit("stale", "feature fingerprint changed", payload)
    raise SystemExit(0)

if validation.get("response_schema_valid") is not True:
    emit("invalid", "response schema not validated", payload)
    raise SystemExit(0)

basis = payload.get("authoritative_basis")
if basis == "validated_markers" and validation.get("marker_validation_passed") is not True:
    emit("invalid", "marker validation required but not passed", payload)
    raise SystemExit(0)
if basis not in ("validated_markers", "validated_inspection"):
    emit("invalid", "unsupported authoritative basis", payload)
    raise SystemExit(0)

emit("hit", "snapshot is reusable", payload)
PY
    ;;

  write)
    [[ -n "$authoritative_basis" \
      && -n "$phase_just_validated" \
      && -n "$earliest_unresolved_phase" \
      && -n "$recommended_next_phase" \
      && -n "$recommended_next_subagent" \
      && -n "$response_file" \
      && -n "$response_sha256" \
      && -n "$response_schema_valid" \
      && -n "$marker_validation_mode" \
      && -n "$marker_validation_passed" ]] || {
      usage
      exit 2
    }

    mkdir -p "$(dirname "$snapshot_file")"

    export SNAPSHOT_FILE="$snapshot_file"
    export FEATURE="$feature"
    export FEATURE_FINGERPRINT="$FEATURE_FINGERPRINT"
    export FINGERPRINT_INPUT_COUNT="$FINGERPRINT_INPUT_COUNT"
    export ARTIFACTS_JSON="$ARTIFACTS_JSON"
    export AUTHORITATIVE_BASIS="$authoritative_basis"
    export PHASE_JUST_VALIDATED="$phase_just_validated"
    export EARLIEST_UNRESOLVED_PHASE="$earliest_unresolved_phase"
    export RECOMMENDED_NEXT_PHASE="$recommended_next_phase"
    export RECOMMENDED_NEXT_SUBAGENT="$recommended_next_subagent"
    export RESPONSE_FILE="$response_file"
    export RESPONSE_SHA256="$response_sha256"
    export RESPONSE_SCHEMA_VALID="$response_schema_valid"
    export MARKER_VALIDATION_MODE="$marker_validation_mode"
    export MARKER_VALIDATION_PASSED="$marker_validation_passed"

    SNAPSHOT_SHA256="$($python_bin - <<'PY'
import datetime as dt
import hashlib
import json
import os
import pathlib
import sys

snapshot_file = pathlib.Path(os.environ["SNAPSHOT_FILE"])
tmp_file = snapshot_file.with_name(snapshot_file.name + ".tmp")
artifacts = json.loads(os.environ["ARTIFACTS_JSON"])
now = dt.datetime.now(dt.timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")

created_at = now
if snapshot_file.exists():
    try:
        old = json.loads(snapshot_file.read_text(encoding="utf-8"))
        created_at = old.get("created_at", now)
    except Exception:
        created_at = now

payload = {
    "schema_version": 1,
    "snapshot_kind": "routing",
    "feature_slug": os.environ["FEATURE"],
    "created_at": created_at,
    "updated_at": now,
    "authoritative_basis": os.environ["AUTHORITATIVE_BASIS"],
    "phase_just_validated": os.environ["PHASE_JUST_VALIDATED"],
    "current": {
        "feature_fingerprint": os.environ["FEATURE_FINGERPRINT"],
        "artifact_count": int(os.environ["FINGERPRINT_INPUT_COUNT"]),
        "earliest_unresolved_phase": os.environ["EARLIEST_UNRESOLVED_PHASE"],
        "recommended_next_phase": os.environ["RECOMMENDED_NEXT_PHASE"],
        "recommended_next_subagent": os.environ["RECOMMENDED_NEXT_SUBAGENT"],
    },
    "validation": {
        "response_file": os.environ["RESPONSE_FILE"],
        "response_sha256": os.environ["RESPONSE_SHA256"],
        "response_schema_valid": os.environ["RESPONSE_SCHEMA_VALID"].lower() == "true",
        "marker_validation_mode": os.environ["MARKER_VALIDATION_MODE"],
        "marker_validation_passed": os.environ["MARKER_VALIDATION_PASSED"].lower() == "true",
        "validated_at": now,
        "validator": "skills/spec-orchestrator/scripts/validate_delegated_run.sh",
    },
    "artifacts": artifacts,
}

serialized = json.dumps(payload, indent=2) + "\n"
tmp_file.write_text(serialized, encoding="utf-8")
readback = json.loads(tmp_file.read_text(encoding="utf-8"))
if readback.get("current", {}).get("feature_fingerprint") != os.environ["FEATURE_FINGERPRINT"]:
    print("snapshot verification failed: feature fingerprint mismatch after write", file=sys.stderr)
    raise SystemExit(1)
if readback.get("current", {}).get("recommended_next_phase") != os.environ["RECOMMENDED_NEXT_PHASE"]:
    print("snapshot verification failed: recommended_next_phase mismatch after write", file=sys.stderr)
    raise SystemExit(1)
if readback.get("current", {}).get("recommended_next_subagent") != os.environ["RECOMMENDED_NEXT_SUBAGENT"]:
    print("snapshot verification failed: recommended_next_subagent mismatch after write", file=sys.stderr)
    raise SystemExit(1)
if readback.get("validation", {}).get("response_sha256") != os.environ["RESPONSE_SHA256"]:
    print("snapshot verification failed: response_sha256 mismatch after write", file=sys.stderr)
    raise SystemExit(1)

tmp_file.replace(snapshot_file)
print("sha256:" + hashlib.sha256(snapshot_file.read_bytes()).hexdigest())
PY
)"

    printf 'SNAPSHOT_STATUS=%q\n' "written"
    printf 'SNAPSHOT_FILE=%q\n' "$snapshot_file"
    printf 'FEATURE_FINGERPRINT=%q\n' "$FEATURE_FINGERPRINT"
    printf 'SNAPSHOT_SHA256=%q\n' "$SNAPSHOT_SHA256"
    printf 'EARLIEST_UNRESOLVED_PHASE=%q\n' "$earliest_unresolved_phase"
    printf 'RECOMMENDED_NEXT_PHASE=%q\n' "$recommended_next_phase"
    printf 'RECOMMENDED_NEXT_SUBAGENT=%q\n' "$recommended_next_subagent"
    ;;

  *)
    echo "Unknown mode: $mode" >&2
    usage
    exit 2
    ;;
esac
