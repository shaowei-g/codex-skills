#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Install a default set of TypeScript-friendly Node.js libraries into the current project.

Usage:
  install_default_libs.sh [--pm npm|pnpm|yarn|bun] [--init-prisma] [--no-types]

Options:
  --pm <name>       Package manager to use (default: auto-detect by lockfile, else npm).
  --init-prisma     Run `prisma init` after installing Prisma packages (skips if ./prisma/schema.prisma exists).
  --no-types        Do not install DefinitelyTyped packages (e.g. @types/express).
  -h, --help        Show help.
EOF
}

pm=""
init_prisma="false"
with_types="true"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --pm)
      pm="${2:-}"
      shift 2
      ;;
    --init-prisma)
      init_prisma="true"
      shift
      ;;
    --no-types)
      with_types="false"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ ! -f package.json ]]; then
  echo "Missing package.json in $(pwd). Initialize a Node project first (e.g. npm init -y)." >&2
  exit 1
fi

detect_pm() {
  if [[ -n "$pm" ]]; then
    echo "$pm"
    return 0
  fi

  if [[ -f pnpm-lock.yaml ]]; then echo "pnpm"; return 0; fi
  if [[ -f yarn.lock ]]; then echo "yarn"; return 0; fi
  if [[ -f bun.lockb || -f bun.lock ]]; then echo "bun"; return 0; fi
  if [[ -f package-lock.json ]]; then echo "npm"; return 0; fi

  if command -v npm >/dev/null 2>&1; then echo "npm"; return 0; fi
  if command -v pnpm >/dev/null 2>&1; then echo "pnpm"; return 0; fi
  if command -v yarn >/dev/null 2>&1; then echo "yarn"; return 0; fi
  if command -v bun >/dev/null 2>&1; then echo "bun"; return 0; fi

  echo "No supported package manager found (npm/pnpm/yarn/bun)." >&2
  exit 1
}

pm="$(detect_pm)"

deps=(
  p-map
  p-retry
  luxon
  lodash-es
  winston
  ioredis
  express
  dotenv
  @prisma/client
)

dev_deps=(
  prisma
  rimraf
  tsc-alias
)

if [[ "$with_types" == "true" ]]; then
  dev_deps+=(
    @types/express
    @types/lodash-es
  )
fi

run_add() {
  local kind="$1"; shift
  case "$pm" in
    npm)
      if [[ "$kind" == "dev" ]]; then npm i -D "$@"; else npm i "$@"; fi
      ;;
    pnpm)
      if [[ "$kind" == "dev" ]]; then pnpm add -D "$@"; else pnpm add "$@"; fi
      ;;
    yarn)
      if [[ "$kind" == "dev" ]]; then yarn add -D "$@"; else yarn add "$@"; fi
      ;;
    bun)
      if [[ "$kind" == "dev" ]]; then bun add -d "$@"; else bun add "$@"; fi
      ;;
    *)
      echo "Unsupported package manager: $pm" >&2
      exit 1
      ;;
  esac
}

run_prisma_init() {
  case "$pm" in
    npm) npx prisma init ;;
    pnpm) pnpm prisma init ;;
    yarn) yarn prisma init ;;
    bun) bunx prisma init ;;
    *)
      echo "Unsupported package manager: $pm" >&2
      exit 1
      ;;
  esac
}

echo "Installing dependencies with: $pm"
run_add prod "${deps[@]}"
run_add dev "${dev_deps[@]}"

if [[ "$init_prisma" == "true" ]]; then
  if [[ -f prisma/schema.prisma ]]; then
    echo "Skipping prisma init (prisma/schema.prisma already exists)."
  else
    echo "Initializing Prisma (creates prisma/schema.prisma + .env)..."
    run_prisma_init
  fi
fi

cat <<EOF

Done.
Notes:
- p-map, p-retry, and lodash-es are ESM-first. If your project compiles to CommonJS, prefer TS "module": "NodeNext"/"Bundler" or use dynamic import.
EOF
