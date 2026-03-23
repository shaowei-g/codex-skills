\
#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
Usage:
  bash ./skills/spec-orchestrator/scripts/materialize_response_artifacts.sh \
    --repo-root /abs/path/to/repo \
    --response-file /abs/path/to/response.md \
    [--feature <feature-slug>] \
    [--allow-prefix <repo-relative-prefix>]...

Parses the approved `Artifacts:` section from a delegated response and writes any
repo-relative artifact payload blocks into the repository.

Rules:
- `Artifacts:` may contain either `- none` or one or more fenced blocks:
    ```artifact path="specs/<feature>/plan.md"
    <full file content>
    ```
- Paths must be repo-relative, must not contain `..`, and must resolve inside --repo-root.
- If one or more --allow-prefix values are provided, every artifact path must start with one of them.
USAGE
}

repo_root=""
response_file=""
feature=""
allow_prefixes=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo-root) repo_root="${2-}"; shift 2 ;;
    --response-file) response_file="${2-}"; shift 2 ;;
    --feature) feature="${2-}"; shift 2 ;;
    --allow-prefix) allow_prefixes+=("${2-}"); shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 2
      ;;
  esac
done

[[ -n "$repo_root" && -n "$response_file" ]] || { usage; exit 2; }
[[ -d "$repo_root" ]] || { echo "repo root not found: $repo_root" >&2; exit 2; }
[[ -f "$response_file" ]] || { echo "response file not found: $response_file" >&2; exit 2; }

if command -v python3 >/dev/null 2>&1; then
  python_bin=python3
elif command -v python >/dev/null 2>&1; then
  python_bin=python
else
  echo "python runtime not found (need python3 or python)" >&2
  exit 127
fi

args=("$response_file" "$repo_root" "$feature")
for prefix in "${allow_prefixes[@]}"; do
  args+=("$prefix")
done

"$python_bin" - "${args[@]}" <<'PY'
import json
import pathlib
import re
import shlex
import sys

response_file = pathlib.Path(sys.argv[1])
repo_root = pathlib.Path(sys.argv[2]).resolve()
allow_prefixes = [p for p in sys.argv[4:] if p]

text = response_file.read_text(encoding="utf-8")
lines = text.splitlines()

sections = {}
current = None
buffer = []
heading_re = re.compile(r'^[A-Za-z][A-Za-z -]*:$')

for line in lines:
    stripped = line.strip()
    if heading_re.match(stripped):
        if current is not None:
            sections[current] = "\n".join(buffer).strip("\n")
        current = stripped
        buffer = []
    elif current is not None:
        buffer.append(line)
if current is not None:
    sections[current] = "\n".join(buffer).strip("\n")

status = ""
for raw in sections.get("Status:", "").splitlines():
    raw = raw.strip()
    if raw.startswith("- "):
        status = raw[2:].strip()
        break

artifacts_section = sections.get("Artifacts:", "").strip()

def q(value: str) -> str:
    return shlex.quote(value)

if status != "completed":
    print(f"ARTIFACT_MATERIALIZATION_STATUS={q('skipped_non_completed')}")
    print(f"ARTIFACT_MATERIALIZATION_COUNT={q('0')}")
    print(f"ARTIFACT_MATERIALIZATION_PATHS_JSON={q('[]')}")
    raise SystemExit(0)

if not artifacts_section or artifacts_section == "- none":
    print(f"ARTIFACT_MATERIALIZATION_STATUS={q('none')}")
    print(f"ARTIFACT_MATERIALIZATION_COUNT={q('0')}")
    print(f"ARTIFACT_MATERIALIZATION_PATHS_JSON={q('[]')}")
    raise SystemExit(0)

pattern = re.compile(r'^```artifact\s+path="([^"\n]+)"[^\n]*\n(.*?)\n```[ \t]*$', re.MULTILINE | re.DOTALL)
matches = list(pattern.finditer(artifacts_section))
if not matches:
    raise SystemExit("Artifacts section does not contain valid artifact fenced blocks")

consumed = []
written_paths = []

for match in matches:
    rel_path = match.group(1)
    content = match.group(2)
    consumed.append(match.span())
    rel = pathlib.PurePosixPath(rel_path)
    if rel.is_absolute():
        raise SystemExit(f"Artifact path must be repo-relative, got absolute path: {rel_path}")
    if ".." in rel.parts:
        raise SystemExit(f"Artifact path must not contain '..': {rel_path}")
    if allow_prefixes and not any(rel_path.startswith(prefix) for prefix in allow_prefixes):
        raise SystemExit(f"Artifact path is outside allowed prefixes: {rel_path}")
    target = (repo_root / rel_path).resolve()
    try:
        target.relative_to(repo_root)
    except ValueError as exc:
        raise SystemExit(f"Artifact path escapes repo root: {rel_path}") from exc
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(content, encoding="utf-8")
    written_paths.append(rel_path)

residual = artifacts_section
for start, end in reversed(consumed):
    residual = residual[:start] + residual[end:]
if residual.strip():
    raise SystemExit("Artifacts section must contain only artifact fenced blocks or '- none'")

print(f"ARTIFACT_MATERIALIZATION_STATUS={q('materialized')}")
print(f"ARTIFACT_MATERIALIZATION_COUNT={q(str(len(written_paths)))}")
print(f"ARTIFACT_MATERIALIZATION_PATHS_JSON={q(json.dumps(written_paths, ensure_ascii=False))}")
PY
