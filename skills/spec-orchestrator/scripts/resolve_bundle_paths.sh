#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
Usage:
  bash ./skills/spec-orchestrator/scripts/resolve_bundle_paths.sh \
    --specialist <spec-viewer|spec-analyst|spec-planner|spec-tasker|spec-implementer|spec-verifier|spec-drift-check|spec-handoff>

Optional:
  --codex-home /abs/path/to/.codex   # defaults to $CODEX_HOME or $HOME/.codex
USAGE
}

specialist=""
codex_home="${CODEX_HOME:-${HOME}/.codex}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --specialist) specialist="${2-}"; shift 2 ;;
    --codex-home) codex_home="${2-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage; exit 2 ;;
  esac
done

[[ -n "$specialist" ]] || { usage; exit 2; }

spec_root="$codex_home/skills/spec-orchestrator"
transport_root="$codex_home/skills/codex-cli-subagent-transport"

printf 'CODEX_HOME=%q\n' "$codex_home"
printf 'SPEC_ORCHESTRATOR_ROOT=%q\n' "$spec_root"
printf 'TRANSPORT_ROOT=%q\n' "$transport_root"
printf 'SPECIALIST_SKILL=%q\n' "$spec_root/$specialist/SKILL.md"
printf 'SUBAGENT_RESPONSE_FORMAT=%q\n' "$spec_root/references/subagent-response-format.md"
printf 'SPECIALIST_STATUS_SEMANTICS=%q\n' "$spec_root/references/specialist-status-semantics.md"
printf 'ARTIFACT_ACCEPTANCE_MARKERS=%q\n' "$spec_root/references/artifact-acceptance-markers.md"
printf 'SUBAGENT_LIFECYCLE=%q\n' "$spec_root/references/subagent-lifecycle.md"
printf 'PROMPT_MAPPING=%q\n' "$spec_root/references/codex-prompt-mapping.md"
printf 'VALIDATE_DELEGATED_RUN=%q\n' "$spec_root/scripts/validate_delegated_run.sh"
printf 'VALIDATE_SUBAGENT_RESPONSE=%q\n' "$spec_root/scripts/validate_subagent_response.sh"
printf 'READ_OR_REFRESH_ROUTING_SNAPSHOT=%q\n' "$spec_root/scripts/read_or_refresh_routing_snapshot.sh"
printf 'TRANSPORT_SKILL=%q\n' "$transport_root/SKILL.md"
printf 'TRANSPORT_RUNNER=%q\n' "$transport_root/scripts/run_codex_cli_subagent.sh"
