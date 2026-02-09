#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: run_postcheck.sh [--with-build] [--continue-on-fail]

Runs TypeScript/JavaScript quality gates in order:
  1) typecheck
  2) lint
  3) test
  4) build (optional)
USAGE
}

WITH_BUILD=0
CONTINUE_ON_FAIL=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --with-build)
      WITH_BUILD=1
      shift
      ;;
    --continue-on-fail)
      CONTINUE_ON_FAIL=1
      shift
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

if [[ ! -f package.json ]]; then
  echo "package.json not found in current directory" >&2
  exit 1
fi

if [[ -f pnpm-lock.yaml ]]; then
  PM="pnpm"
  RUN=(pnpm run)
elif [[ -f yarn.lock ]]; then
  PM="yarn"
  RUN=(yarn)
else
  PM="npm"
  RUN=(npm run)
fi

echo "[postcheck] package manager: ${PM}"

run_gate() {
  local label="$1"
  shift

  echo "[postcheck] start: ${label}"
  if "$@"; then
    echo "[postcheck] pass: ${label}"
    return 0
  fi

  echo "[postcheck] fail: ${label}" >&2
  if [[ "${CONTINUE_ON_FAIL}" -eq 1 ]]; then
    return 1
  fi
  exit 1
}

has_script() {
  local script_name="$1"
  node -e '
const fs = require("fs");
const file = JSON.parse(fs.readFileSync("package.json", "utf8"));
const name = process.argv[1];
process.exit(file.scripts && file.scripts[name] ? 0 : 1);
' "$script_name"
}

TYPECHECK_CMD=()
if has_script "typecheck"; then
  TYPECHECK_CMD=("${RUN[@]}" typecheck)
elif has_script "type-check"; then
  TYPECHECK_CMD=("${RUN[@]}" type-check)
else
  TYPECHECK_CMD=(npx tsc -p tsconfig.json --noEmit)
fi

LINT_CMD=()
if has_script "lint"; then
  LINT_CMD=("${RUN[@]}" lint)
fi

TEST_CMD=()
if has_script "test"; then
  TEST_CMD=("${RUN[@]}" test)
fi

BUILD_CMD=()
if [[ "${WITH_BUILD}" -eq 1 ]] && has_script "build"; then
  BUILD_CMD=("${RUN[@]}" build)
fi

FAILURES=0
run_gate "typecheck" "${TYPECHECK_CMD[@]}" || FAILURES=$((FAILURES + 1))

if [[ ${#LINT_CMD[@]} -gt 0 ]]; then
  run_gate "lint" "${LINT_CMD[@]}" || FAILURES=$((FAILURES + 1))
else
  echo "[postcheck] skip: lint (script not found)"
fi

if [[ ${#TEST_CMD[@]} -gt 0 ]]; then
  run_gate "test" "${TEST_CMD[@]}" || FAILURES=$((FAILURES + 1))
else
  echo "[postcheck] skip: test (script not found)"
fi

if [[ ${#BUILD_CMD[@]} -gt 0 ]]; then
  run_gate "build" "${BUILD_CMD[@]}" || FAILURES=$((FAILURES + 1))
elif [[ "${WITH_BUILD}" -eq 1 ]]; then
  echo "[postcheck] skip: build (script not found)"
fi

if [[ "${FAILURES}" -gt 0 ]]; then
  echo "[postcheck] completed with ${FAILURES} failing gate(s)" >&2
  exit 1
fi

echo "[postcheck] all requested gates passed"
