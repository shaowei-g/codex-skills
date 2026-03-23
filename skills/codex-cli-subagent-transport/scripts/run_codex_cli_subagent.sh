#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
Usage:
  bash ./scripts/run_codex_cli_subagent.sh \
    --repo-root /abs/path/to/repo \
    --feature <feature-slug> \
    --phase <phase> \
    --subagent <subagent> \
    --prompt-file /abs/path/to/prompt.md \
    [--model gpt-5.4-mini] \
    [--run-id custom-id] \
    [--run-root .codex/codex-cli-subagent-runs]

Creates a repo-local run directory, copies the prompt into it, runs one `codex exec`, and
prints shell-escaped manifest assignments to stdout. The manifest is the authoritative locator contract.
USAGE
}

repo_root=""
feature=""
phase=""
subagent=""
prompt_file=""
model="gpt-5.4-mini"
run_id=""
run_root=".codex/codex-cli-subagent-runs"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo-root)
      repo_root="$2"
      shift 2
      ;;
    --feature)
      feature="$2"
      shift 2
      ;;
    --phase)
      phase="$2"
      shift 2
      ;;
    --subagent)
      subagent="$2"
      shift 2
      ;;
    --prompt-file)
      prompt_file="$2"
      shift 2
      ;;
    --model)
      model="$2"
      shift 2
      ;;
    --run-id)
      run_id="$2"
      shift 2
      ;;
    --run-root)
      run_root="$2"
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

[[ -n "$repo_root" && -n "$feature" && -n "$phase" && -n "$subagent" && -n "$prompt_file" ]] || {
  usage
  exit 2
}

[[ -d "$repo_root" ]] || { echo "repo root not found: $repo_root" >&2; exit 2; }
[[ -f "$prompt_file" ]] || { echo "prompt file not found: $prompt_file" >&2; exit 2; }
command -v codex >/dev/null 2>&1 || { echo "codex CLI not found in PATH" >&2; exit 127; }

if [[ -z "$run_id" ]]; then
  ts="$(date -u +%Y%m%dT%H%M%SZ)"
  pid="$$"
  run_id="${feature}-${phase}-${subagent}-${ts}-${pid}"
fi

sanitize() {
  printf '%s' "$1" | tr '/ ' '__' | tr -cd '[:alnum:]_.:-'
}

safe_feature="$(sanitize "$feature")"
safe_phase="$(sanitize "$phase")"
safe_subagent="$(sanitize "$subagent")"
safe_run_id="$(sanitize "$run_id")"

run_dir="$repo_root/$run_root/$safe_feature/${safe_phase}-${safe_subagent}-${safe_run_id}"
mkdir -p "$run_dir"

prompt_copy="$run_dir/prompt.md"
response_file="$run_dir/response.md"
exec_log="$run_dir/exec.log"
manifest_env="$run_dir/manifest.env"
manifest_json="$run_dir/manifest.json"

cp "$prompt_file" "$prompt_copy"

set +e
(
  cd "$repo_root"
  codex exec --model "$model" -c model_reasoning_effort="low" -o "$response_file" - < "$prompt_copy" > "$exec_log" 2>&1
)
exit_code=$?
set -e

python3 - <<PY
import json
from pathlib import Path
manifest = {
  "repo_root": ${repo_root@Q},
  "feature": ${feature@Q},
  "phase": ${phase@Q},
  "subagent": ${subagent@Q},
  "model": ${model@Q},
  "run_id": ${run_id@Q},
  "run_dir": ${run_dir@Q},
  "prompt_file": ${prompt_copy@Q},
  "response_file": ${response_file@Q},
  "exec_log": ${exec_log@Q},
  "manifest_env": ${manifest_env@Q},
  "manifest_json": ${manifest_json@Q},
  "exit_code": $exit_code,
}
Path(${manifest_json@Q}).write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
PY

{
  printf 'REPO_ROOT=%q\n' "$repo_root"
  printf 'FEATURE=%q\n' "$feature"
  printf 'PHASE=%q\n' "$phase"
  printf 'SUBAGENT=%q\n' "$subagent"
  printf 'MODEL=%q\n' "$model"
  printf 'RUN_ID=%q\n' "$run_id"
  printf 'RUN_DIR=%q\n' "$run_dir"
  printf 'PROMPT_FILE=%q\n' "$prompt_copy"
  printf 'RESPONSE_FILE=%q\n' "$response_file"
  printf 'EXEC_LOG=%q\n' "$exec_log"
  printf 'MANIFEST_ENV=%q\n' "$manifest_env"
  printf 'MANIFEST_JSON=%q\n' "$manifest_json"
  printf 'EXIT_CODE=%q\n' "$exit_code"
} | tee "$manifest_env"

exit 0
