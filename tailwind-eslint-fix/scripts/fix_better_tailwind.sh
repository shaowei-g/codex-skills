#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR=""
TARGET='src/**/*.{ts,tsx,js,jsx}'
PM="auto"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project-dir)
      PROJECT_DIR="${2:-}"
      shift 2
      ;;
    --target)
      TARGET="${2:-}"
      shift 2
      ;;
    --pm)
      PM="${2:-}"
      shift 2
      ;;
    -h|--help)
      cat <<'USAGE'
Usage:
  fix_better_tailwind.sh --project-dir <dir> [--target "<glob-or-files>"] [--pm <auto|pnpm|yarn|npm>]

Examples:
  fix_better_tailwind.sh --project-dir packages/eKoEN
  fix_better_tailwind.sh --project-dir packages/eKoEN --pm auto
  fix_better_tailwind.sh --project-dir packages/eKoEN --pm pnpm
  fix_better_tailwind.sh --project-dir packages/eKoEN --pm yarn
  fix_better_tailwind.sh --project-dir packages/eKoEN --pm npm
  fix_better_tailwind.sh --project-dir packages/eKoEN --target "src/**/*.tsx"
  fix_better_tailwind.sh --project-dir packages/eKoEN --target "src/a.tsx src/b.tsx"
USAGE
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

if [[ -z "$PROJECT_DIR" ]]; then
  echo "Missing required argument: --project-dir" >&2
  exit 1
fi

if [[ ! -d "$PROJECT_DIR" ]]; then
  echo "Project directory not found: $PROJECT_DIR" >&2
  exit 1
fi

if [[ "$PM" != "auto" && "$PM" != "pnpm" && "$PM" != "yarn" && "$PM" != "npm" ]]; then
  echo "Invalid --pm value: $PM (allowed: auto|pnpm|yarn|npm)" >&2
  exit 1
fi

if [[ "$PM" == "auto" ]]; then
  if [[ -f "$PROJECT_DIR/pnpm-lock.yaml" ]]; then
    PM="pnpm"
  elif [[ -f "$PROJECT_DIR/yarn.lock" ]]; then
    PM="yarn"
  elif [[ -f "$PROJECT_DIR/package-lock.json" || -f "$PROJECT_DIR/npm-shrinkwrap.json" ]]; then
    PM="npm"
  elif command -v pnpm >/dev/null 2>&1; then
    PM="pnpm"
  elif command -v yarn >/dev/null 2>&1; then
    PM="yarn"
  else
    PM="npm"
  fi
fi

if ! command -v "$PM" >/dev/null 2>&1; then
  echo "Package manager '$PM' is not installed in PATH." >&2
  exit 1
fi

TARGET_ARGS=()
set -f
# shellcheck disable=SC2206
TARGET_ARGS=($TARGET)
set +f

run_eslint() {
  local -a args=("$@")

  case "$PM" in
    pnpm)
      pnpm --dir "$PROJECT_DIR" exec eslint "${args[@]}"
      ;;
    yarn)
      yarn --cwd "$PROJECT_DIR" eslint "${args[@]}"
      ;;
    npm)
      (
        cd "$PROJECT_DIR"
        npm exec eslint -- "${args[@]}"
      )
      ;;
    *)
      echo "Unsupported package manager: $PM" >&2
      exit 1
      ;;
  esac
}

echo "[tailwind-eslint-fix] Running eslint --fix"
echo "  project: $PROJECT_DIR"
echo "  pm     : $PM"
echo "  target : $TARGET"

run_eslint "${TARGET_ARGS[@]}" --fix

echo "[tailwind-eslint-fix] Checking remaining better-tailwindcss findings"
REPORT=$(run_eslint "${TARGET_ARGS[@]}" -f unix 2>&1 || true)

if command -v rg >/dev/null 2>&1; then
  MATCHES=$(printf '%s\n' "$REPORT" | rg "better-tailwindcss" || true)
else
  MATCHES=$(printf '%s\n' "$REPORT" | grep "better-tailwindcss" || true)
fi

if [[ -n "$MATCHES" ]]; then
  echo "[tailwind-eslint-fix] Remaining better-tailwindcss findings:"
  printf '%s\n' "$MATCHES"
  exit 2
fi

echo "[tailwind-eslint-fix] No remaining better-tailwindcss findings."
