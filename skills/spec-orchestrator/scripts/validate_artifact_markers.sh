#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  validate_artifact_markers.sh [--require-markers] <specs/feature-path>

Validate artifact acceptance markers for one feature directory.
Use --require-markers when the phase-owned artifacts are expected to carry
YAML front matter markers and missing markers should fail the check.
EOF
}

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

args=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --help|-h)
      usage
      exit 0
      ;;
    *)
      args+=("$1")
      shift
      ;;
  esac
done

python3 "$script_dir/validate_artifact_markers.py" "${args[@]}"
