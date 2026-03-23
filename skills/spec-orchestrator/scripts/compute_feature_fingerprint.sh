#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
Usage:
  bash ./skills/spec-orchestrator/scripts/compute_feature_fingerprint.sh \
    --repo-root /abs/path/to/repo \
    --feature <feature-slug>

Prints shell-safe assignments:
  FEATURE
  FEATURE_DIR
  FEATURE_EXISTS
  FEATURE_FINGERPRINT
  FINGERPRINT_INPUT_COUNT
  ARTIFACTS_JSON
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

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo-root)
      repo_root="${2-}"
      shift 2
      ;;
    --feature)
      feature="${2-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 2
      ;;
  esac
done

[[ -n "$repo_root" && -n "$feature" ]] || { usage; exit 2; }
[[ -d "$repo_root" ]] || { echo "repo root not found: $repo_root" >&2; exit 2; }

python_bin="$(select_python)"

"$python_bin" - "$repo_root" "$feature" <<'PY'
import hashlib
import json
import pathlib
import shlex
import sys

repo_root = pathlib.Path(sys.argv[1]).resolve()
feature = sys.argv[2]
feature_dir = repo_root / "specs" / feature

def q(value):
    return shlex.quote(value)

if not feature_dir.exists():
    print(f"FEATURE={q(feature)}")
    print(f"FEATURE_DIR={q(str(feature_dir))}")
    print("FEATURE_EXISTS=0")
    print("FEATURE_FINGERPRINT=absent")
    print("FINGERPRINT_INPUT_COUNT=0")
    print(f"ARTIFACTS_JSON={q('[]')}")
    raise SystemExit(0)

artifacts = []
aggregate = hashlib.sha256()

for path in sorted(feature_dir.rglob("*")):
    if not path.is_file():
        continue

    rel = path.relative_to(repo_root).as_posix()
    digest = hashlib.sha256(path.read_bytes()).hexdigest()

    artifacts.append({
        "path": rel,
        "sha256": digest,
    })

    aggregate.update(rel.encode("utf-8"))
    aggregate.update(b"\0")
    aggregate.update(digest.encode("ascii"))
    aggregate.update(b"\n")

feature_fingerprint = f"sha256:{aggregate.hexdigest()}"

print(f"FEATURE={q(feature)}")
print(f"FEATURE_DIR={q(str(feature_dir))}")
print("FEATURE_EXISTS=1")
print(f"FEATURE_FINGERPRINT={q(feature_fingerprint)}")
print(f"FINGERPRINT_INPUT_COUNT={len(artifacts)}")
print(f"ARTIFACTS_JSON={q(json.dumps(artifacts, separators=(',', ':')))}")
PY
