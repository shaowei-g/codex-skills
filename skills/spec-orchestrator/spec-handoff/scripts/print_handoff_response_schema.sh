\
#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  print_handoff_response_schema.sh \
    --status <completed|blocked|rejected> \
    --feature <feature-slug> \
    --scope <single scope> \
    [--result <text>] \
    [--artifacts <none|fence-template>] \
    [--recommended-next-phase <phase>] \
    [--recommended-next-subagent <subagent>]
EOF
}

status=""
feature=""
scope=""
result="none"
artifacts="none"
recommended_next_phase="none"
recommended_next_subagent="none"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --status) status=${2-}; shift 2 ;;
    --feature) feature=${2-}; shift 2 ;;
    --scope) scope=${2-}; shift 2 ;;
    --result) result=${2-}; shift 2 ;;
    --artifacts) artifacts=${2-}; shift 2 ;;
    --recommended-next-phase) recommended_next_phase=${2-}; shift 2 ;;
    --recommended-next-subagent) recommended_next_subagent=${2-}; shift 2 ;;
    --help|-h) usage; exit 0 ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

[[ -n "$status" && -n "$feature" && -n "$scope" ]] || { echo "Missing required arguments: --status, --feature, --scope" >&2; usage >&2; exit 1; }
case "$status" in completed|blocked|rejected) ;; *) echo "Invalid --status: $status" >&2; exit 1 ;; esac
case "$recommended_next_phase" in inspection|specification|planning|"task decomposition"|implementation|verification|"drift check"|handoff|none) ;; *) echo "Invalid --recommended-next-phase: $recommended_next_phase" >&2; exit 1 ;; esac
case "$recommended_next_subagent" in spec-viewer|spec-analyst|spec-planner|spec-tasker|spec-implementer|spec-verifier|spec-drift-check|spec-handoff|none) ;; *) echo "Invalid --recommended-next-subagent: $recommended_next_subagent" >&2; exit 1 ;; esac
case "$artifacts" in none|fence-template) ;; *) echo "Invalid --artifacts: $artifacts" >&2; exit 1 ;; esac

printf 'Status:\n\n- %s\n\n' "$status"
printf 'Feature-Slug:\n\n- %s\n\n' "$feature"
printf 'Assigned-Phase:\n\n- handoff\n\n'
printf 'Assigned-Subagent:\n\n- spec-handoff\n\n'
printf 'Scope:\n\n- %s\n\n' "$scope"
printf 'Result:\n\n%s\n\n' "$result"
printf 'Artifacts:\n\n'
if [[ "$artifacts" == "none" ]]; then
  printf '%s\n\n' '- none'
else
  cat <<'EOF'
```artifact path="specs/<feature>/handoff.md"
<full file content>
```

EOF
fi
printf 'Recommended-Next-Phase:\n\n- %s\n\n' "$recommended_next_phase"
printf 'Recommended-Next-Subagent:\n\n- %s\n\n' "$recommended_next_subagent"
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
