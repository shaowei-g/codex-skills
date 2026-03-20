#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  print_subagent_response_schema.sh \
    --status <completed|blocked|rejected> \
    --feature <feature-slug> \
    --assigned-phase <phase> \
    --assigned-subagent <subagent> \
    --scope <single scope> \
    [--summary <text>] \
    [--files-changed <text>] \
    [--files-read <text>] \
    [--missing-prerequisites <text>] \
    [--contract-violations <text>] \
    [--blockers <text>] \
    [--unresolved-questions <text>] \
    [--drift <text>] \
    [--evidence <text>] \
    [--recommended-next-phase <phase>] \
    [--recommended-next-subagent <subagent>] \
    [--notes <text>]
EOF
}

status=""
feature=""
assigned_phase=""
assigned_subagent=""
scope=""
summary="none"
files_changed="none"
files_read="none"
missing_prerequisites="none"
contract_violations="none"
blockers="none"
unresolved_questions="none"
drift="none"
evidence="none"
recommended_next_phase="none"
recommended_next_subagent="none"
notes="none"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --status)
      status=${2-}
      shift 2
      ;;
    --feature)
      feature=${2-}
      shift 2
      ;;
    --assigned-phase)
      assigned_phase=${2-}
      shift 2
      ;;
    --assigned-subagent)
      assigned_subagent=${2-}
      shift 2
      ;;
    --scope)
      scope=${2-}
      shift 2
      ;;
    --summary)
      summary=${2-}
      shift 2
      ;;
    --files-changed)
      files_changed=${2-}
      shift 2
      ;;
    --files-read)
      files_read=${2-}
      shift 2
      ;;
    --missing-prerequisites)
      missing_prerequisites=${2-}
      shift 2
      ;;
    --contract-violations)
      contract_violations=${2-}
      shift 2
      ;;
    --blockers)
      blockers=${2-}
      shift 2
      ;;
    --unresolved-questions)
      unresolved_questions=${2-}
      shift 2
      ;;
    --drift)
      drift=${2-}
      shift 2
      ;;
    --evidence)
      evidence=${2-}
      shift 2
      ;;
    --recommended-next-phase)
      recommended_next_phase=${2-}
      shift 2
      ;;
    --recommended-next-subagent)
      recommended_next_subagent=${2-}
      shift 2
      ;;
    --notes)
      notes=${2-}
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ -z "$status" || -z "$feature" || -z "$assigned_phase" || -z "$assigned_subagent" || -z "$scope" ]]; then
  echo "Missing required arguments: --status, --feature, --assigned-phase, --assigned-subagent, --scope" >&2
  usage >&2
  exit 1
fi

case "$status" in
  completed|blocked|rejected) ;;
  *)
    echo "Invalid --status: $status" >&2
    exit 1
    ;;
esac

case "$assigned_phase" in
  inspection|specification|planning|"task decomposition"|implementation|verification|"drift check"|handoff) ;;
  *)
    echo "Invalid --assigned-phase: $assigned_phase" >&2
    exit 1
    ;;
esac

case "$assigned_subagent" in
  spec-viewer|spec-analyst|spec-planner|spec-tasker|spec-implementer|spec-verifier|spec-drift-check|spec-handoff) ;;
  *)
    echo "Invalid --assigned-subagent: $assigned_subagent" >&2
    exit 1
    ;;
esac

case "$recommended_next_phase" in
  inspection|specification|planning|"task decomposition"|implementation|verification|"drift check"|handoff|none) ;;
  *)
    echo "Invalid --recommended-next-phase: $recommended_next_phase" >&2
    exit 1
    ;;
esac

case "$recommended_next_subagent" in
  spec-viewer|spec-analyst|spec-planner|spec-tasker|spec-implementer|spec-verifier|spec-drift-check|spec-handoff|none) ;;
  *)
    echo "Invalid --recommended-next-subagent: $recommended_next_subagent" >&2
    exit 1
    ;;
esac

printf 'Status:\n\n- %s\n\n' "$status"
printf 'Feature-Slug:\n\n- %s\n\n' "$feature"
printf 'Assigned-Phase:\n\n- %s\n\n' "$assigned_phase"
printf 'Assigned-Subagent:\n\n- %s\n\n' "$assigned_subagent"
printf 'Scope:\n\n- %s\n\n' "$scope"
printf 'Summary:\n\n%s\n\n' "$summary"
printf 'Files-Changed:\n\n%s\n\n' "$files_changed"
printf 'Files-Read:\n\n%s\n\n' "$files_read"
printf 'Missing-Prerequisites:\n\n%s\n\n' "$missing_prerequisites"
printf 'Contract-Violations:\n\n%s\n\n' "$contract_violations"
printf 'Blockers:\n\n%s\n\n' "$blockers"
printf 'Unresolved Questions:\n\n%s\n\n' "$unresolved_questions"
printf 'Drift:\n\n%s\n\n' "$drift"
printf 'Evidence:\n\n%s\n\n' "$evidence"
printf 'Recommended-Next-Phase:\n\n- %s\n\n' "$recommended_next_phase"
printf 'Recommended-Next-Subagent:\n\n- %s\n\n' "$recommended_next_subagent"
printf 'Notes:\n\n%s\n\n' "$notes"
cat <<'EOF'
Self-Check:

- one_bounded_scope = true
- assigned_phase_only = true
- chose_next_phase = false
- chose_next_subagent = false
- unauthorized_handoff = false
- outside_ownership_modification = false
- required_response_schema_used = true
- terminating_now = true
EOF