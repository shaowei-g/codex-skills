#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

usage() {
   cat <<'EOF'
Usage:
   prepare_handoff.sh --feature <feature-slug> [options]

Options:
   --repo-root <path>   Repository root containing specs/ (default: current directory)
   --scope <text>       Single bounded handoff scope
   --write              Write specs/<feature>/handoff.md
   --help, -h           Show help

The script reads feature artifacts, derives handoff state, optionally writes handoff.md,
and emits the fixed handoff response schema.
EOF
}

block_has_meaningful_content() {
   local text=$1
   local trimmed

   trimmed=$(printf '%s\n' "$text" | trim_blank_lines)
   [[ -n "$trimmed" ]] || return 1
   ! grep -Eq '^[[:space:]]*-[[:space:]]*none[[:space:]]*$' <<<"$trimmed"
}

read_section() {
   local file=$1
   local heading=$2

   [[ -f "$file" ]] || return 0

   awk -v heading="$heading" '
      $0 == "## " heading { in_section = 1; next }
      in_section && /^## / { exit }
      in_section { print }
   ' "$file"
}

read_first_available_section() {
   local file=$1
   shift

   local heading
   local content

   for heading in "$@"; do
      content=$(read_section "$file" "$heading")
      if grep -q '[^[:space:]]' <<<"$content"; then
         printf '%s\n' "$content"
         return 0
      fi
   done
}

trim_blank_lines() {
   awk '
      { lines[NR] = $0 }
      END {
         start = 1
         while (start <= NR && lines[start] ~ /^[[:space:]]*$/) start++
         end = NR
         while (end >= start && lines[end] ~ /^[[:space:]]*$/) end--
         for (i = start; i <= end; i++) print lines[i]
      }
   '
}

normalize_block() {
   local text=$1

   if ! grep -q '[^[:space:]]' <<<"$text"; then
      printf '%s\n' "- none"
      return
   fi

   printf '%s\n' "$text" | trim_blank_lines
}

bulletize_block() {
   local text=$1

   if ! grep -q '[^[:space:]]' <<<"$text"; then
      printf '%s\n' "- none"
      return
   fi

   printf '%s\n' "$text" | awk '
      /^[[:space:]]*$/ { next }
      /^[[:space:]]*[-*][[:space:]]/ { print; next }
      { print "- " $0 }
   ' | trim_blank_lines
}

merge_blocks() {
   local combined=""
   local item

   for item in "$@"; do
      if block_has_meaningful_content "$item"; then
         if [[ -n "$combined" ]]; then
            combined+=$'\n'
         fi
         combined+=$(printf '%s\n' "$item" | trim_blank_lines)
      fi
   done

   if [[ -z "$combined" ]]; then
      printf '%s\n' "- none"
      return
   fi

   printf '%s\n' "$combined" | awk '!seen[$0]++'
}

collect_task_lines() {
   local file=$1
   local pattern=$2

   [[ -f "$file" ]] || return 0
   grep -E "$pattern" "$file" | sed -E 's/^[-*] \[[ xX]\][[:space:]]*/- /'
}

extract_review_findings_by_type() {
   local review_file=$1
   local finding_type=$2
   local findings
   local pattern

   findings=$(read_first_available_section "$review_file" "Findings" "Review Findings")

   case "$finding_type" in
      blocker)
         pattern='blocker'
         ;;
      drift)
         pattern='drift'
         ;;
      stale-artifact)
         pattern='stale artifact|stale-artifact'
         ;;
      *)
         printf '%s\n' "- none"
         return
         ;;
   esac

   if ! grep -Eqi "$pattern" <<<"$findings"; then
      printf '%s\n' "- none"
      return
   fi

   bulletize_block "$(grep -Ei "$pattern" <<<"$findings")"
}

extract_review_blockers() {
   local review_file=$1
   local explicit_blockers
   local typed_blockers

   explicit_blockers=$(read_first_available_section "$review_file" "Blockers" "Blocking Issues")
   typed_blockers=$(extract_review_findings_by_type "$review_file" blocker)

   merge_blocks "$(bulletize_block "$explicit_blockers")" "$typed_blockers"
}

extract_review_evidence() {
   local review_file=$1
   local evidence

   evidence=$(read_first_available_section "$review_file" "Evidence" "Verification Evidence")
   bulletize_block "$evidence"
}

extract_review_next_phase() {
   local review_file=$1
   local recommendation

   recommendation=$(read_first_available_section "$review_file" "Recommended Next Phase" "Recommended Next Step" "Recommendation")
   printf '%s\n' "$recommendation"
}

extract_review_drift() {
   local review_file=$1

   extract_review_findings_by_type "$review_file" drift
}

extract_review_stale_artifacts() {
   local review_file=$1

   extract_review_findings_by_type "$review_file" stale-artifact
}

extract_drift_summary() {
   local drift_file=$1
   local discovery
   local reason
   local blocking_decision
   local recommendation

   discovery=$(read_first_available_section "$drift_file" "Out-of-Scope Request or Discovery")
   reason=$(read_first_available_section "$drift_file" "Why It Exceeds the Current Spec")
   blocking_decision=$(read_first_available_section "$drift_file" "Blocking Decision")
   recommendation=$(read_first_available_section "$drift_file" "Recommendation")

   merge_blocks \
      "$(bulletize_block "$discovery")" \
      "$(bulletize_block "$reason")" \
      "$(bulletize_block "$blocking_decision")" \
      "$(bulletize_block "$recommendation")"
}

extract_drift_blockers() {
   local drift_file=$1
   local blocking_decision

   blocking_decision=$(read_first_available_section "$drift_file" "Blocking Decision")
   if grep -Eqi 'blocked pending|blocked|cannot continue' <<<"$blocking_decision"; then
      bulletize_block "$blocking_decision"
   else
      printf '%s\n' "- none"
   fi
}

infer_phase_from_text() {
   local text=$1

   if grep -qi 'specification\|spec.md' <<<"$text"; then
      printf '%s\n' "specification"
   elif grep -qi 'planning\|plan.md' <<<"$text"; then
      printf '%s\n' "planning"
   elif grep -qi 'task decomposition\|tasks.md' <<<"$text"; then
      printf '%s\n' "task decomposition"
   elif grep -qi 'implementation' <<<"$text"; then
      printf '%s\n' "implementation"
   elif grep -qi 'verification\|review' <<<"$text"; then
      printf '%s\n' "verification"
   elif grep -qi 'drift' <<<"$text"; then
      printf '%s\n' "drift check"
   elif grep -qi 'handoff' <<<"$text"; then
      printf '%s\n' "handoff"
   else
      printf '%s\n' ""
   fi
}

first_nonempty_line() {
   awk 'NF { print; exit }'
}

join_paths_as_bullets() {
   local path

   if [[ $# -eq 0 ]]; then
      printf '%s\n' "- none"
      return
   fi

   for path in "$@"; do
      printf '%s\n' "- $path"
   done
}

derive_phase() {
   local spec_file=$1
   local plan_file=$2
   local tasks_file=$3
   local review_file=$4

   if [[ ! -f "$spec_file" ]]; then
      printf '%s\n' "specification"
   elif [[ ! -f "$plan_file" ]]; then
      printf '%s\n' "planning"
   elif [[ ! -f "$tasks_file" ]]; then
      printf '%s\n' "task decomposition"
   elif [[ -f "$review_file" ]]; then
      printf '%s\n' "verification"
   else
      printf '%s\n' "implementation"
   fi
}

recommend_next_phase() {
   local spec_file=$1
   local plan_file=$2
   local tasks_file=$3
   local review_file=$4
   local pending_tasks=$5

   if [[ ! -f "$spec_file" ]]; then
      printf '%s\n' "specification"
   elif [[ ! -f "$plan_file" ]]; then
      printf '%s\n' "planning"
   elif [[ ! -f "$tasks_file" ]]; then
      printf '%s\n' "task decomposition"
   elif grep -q '[^[:space:]]' <<<"$pending_tasks"; then
      printf '%s\n' "implementation"
   elif [[ ! -f "$review_file" ]]; then
      printf '%s\n' "verification"
   else
      printf '%s\n' "handoff"
   fi
}

recommend_next_subagent() {
   case "$1" in
   inspection) printf '%s\n' "spec-handoff" ;;
      specification) printf '%s\n' "spec-analyst" ;;
      planning) printf '%s\n' "spec-planner" ;;
      "task decomposition") printf '%s\n' "spec-tasker" ;;
      implementation) printf '%s\n' "spec-implementer" ;;
      verification) printf '%s\n' "spec-verifier" ;;
      "drift check") printf '%s\n' "spec-drift-check" ;;
      handoff) printf '%s\n' "spec-handoff" ;;
      *) printf '%s\n' "none" ;;
   esac
}

recommend_first_file() {
   local feature_dir=$1
   local phase=$2

   case "$phase" in
      specification) printf '%s\n' "$feature_dir/spec.md" ;;
      planning) printf '%s\n' "$feature_dir/spec.md" ;;
      "task decomposition") printf '%s\n' "$feature_dir/plan.md" ;;
      implementation) printf '%s\n' "$feature_dir/tasks.md" ;;
      verification) printf '%s\n' "$feature_dir/review.md" ;;
      handoff) printf '%s\n' "$feature_dir/handoff.md" ;;
      *) printf '%s\n' "$feature_dir" ;;
   esac
}

repo_root=$PWD
feature=""
scope="prepare one handoff update"
write_handoff=false

while [[ $# -gt 0 ]]; do
   case "$1" in
      --repo-root)
         repo_root=${2-}
         shift 2
         ;;
      --feature)
         feature=${2-}
         shift 2
         ;;
      --scope)
         scope=${2-}
         shift 2
         ;;
      --write)
         write_handoff=true
         shift
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

if [[ -z "$feature" ]]; then
   echo "Missing required argument: --feature" >&2
   usage >&2
   exit 1
fi

feature_dir=$repo_root/specs/$feature
handoff_file=$feature_dir/handoff.md
spec_file=$feature_dir/spec.md
plan_file=$feature_dir/plan.md
tasks_file=$feature_dir/tasks.md
review_file=$feature_dir/review.md
drift_file=$feature_dir/drift.md

if [[ ! -d "$feature_dir" ]]; then
   "$SCRIPT_DIR/print_handoff_response_schema.sh" \
      --status blocked \
      --feature "$feature" \
      --scope "$scope" \
      --missing-prerequisites "- Missing feature directory: $feature_dir" \
      --blockers "- Cannot prepare handoff without specs/$feature" \
      --evidence "- Checked feature directory existence" \
      --notes "- Allowed updates are limited to handoff.md" \
      --recommended-next-phase specification \
      --recommended-next-subagent spec-analyst
   exit 0
fi

files_read=()
for candidate in \
   "$repo_root/.codex/prompts/speckit.checklist.md" \
   "$repo_root/.codex/prompts/speckit.constitution.md" \
   "$handoff_file" \
   "$spec_file" \
   "$plan_file" \
   "$tasks_file" \
   "$review_file" \
   "$drift_file"; do
   if [[ -f "$candidate" ]]; then
      files_read+=("${candidate#$repo_root/}")
   fi
done

current_phase=$(derive_phase "$spec_file" "$plan_file" "$tasks_file" "$review_file")

completed_work=$(read_section "$handoff_file" "Completed Work")
if ! grep -q '[^[:space:]]' <<<"$completed_work"; then
   completed_work=$(collect_task_lines "$tasks_file" '^[-*][[:space:]]+\[[xX]\]')
fi
completed_work=$(normalize_block "$completed_work")

pending_work=$(read_section "$handoff_file" "Pending Work")
if ! grep -q '[^[:space:]]' <<<"$pending_work"; then
   pending_work=$(collect_task_lines "$tasks_file" '^[-*][[:space:]]+\[[[:space:]]\]')
fi
pending_work=$(normalize_block "$pending_work")

blockers=$(read_section "$handoff_file" "Blockers")
review_blockers=$(extract_review_blockers "$review_file")
drift_blockers=$(extract_drift_blockers "$drift_file")
blockers=$(merge_blocks "$(normalize_block "$blockers")" "$review_blockers" "$drift_blockers")

unresolved_questions=$(read_first_available_section "$spec_file" "Open Questions" "Unresolved Questions")
if ! grep -q '[^[:space:]]' <<<"$unresolved_questions"; then
   unresolved_questions=$(read_first_available_section "$review_file" "Unresolved Questions" "Open Questions")
fi
unresolved_questions=$(normalize_block "$unresolved_questions")

review_evidence=$(extract_review_evidence "$review_file")
review_drift=$(extract_review_drift "$review_file")
review_stale_artifacts=$(extract_review_stale_artifacts "$review_file")
drift=$(merge_blocks "$review_drift" "$(extract_drift_summary "$drift_file")")

if ! block_has_meaningful_content "$drift"; then
   drift='- none'
fi

recommended_next_phase=$(recommend_next_phase "$spec_file" "$plan_file" "$tasks_file" "$review_file" "$pending_work")
review_next_phase=$(infer_phase_from_text "$(extract_review_next_phase "$review_file")")
drift_next_phase=$(infer_phase_from_text "$(read_first_available_section "$drift_file" "Recommendation" "Blocking Decision")")

if [[ -n "$drift_next_phase" ]]; then
   recommended_next_phase=$drift_next_phase
elif [[ -n "$review_next_phase" ]]; then
   recommended_next_phase=$review_next_phase
fi

recommended_next_subagent=$(recommend_next_subagent "$recommended_next_phase")
recommended_first_file=$(recommend_first_file "$feature_dir" "$recommended_next_phase")
recommended_next_step="- $recommended_next_phase; first read ${recommended_first_file#$repo_root/}"

summary="- Prepared handoff state from feature artifacts"
files_changed='- none'

if $write_handoff; then
   handoff_content=$("$SCRIPT_DIR/render_handoff_template.sh" \
      --phase "$current_phase" \
      --completed "$completed_work" \
      --pending "$pending_work" \
      --blockers "$blockers" \
      --next-step "$recommended_next_step")
   printf '%s\n' "$handoff_content" > "$handoff_file"
   files_changed="- specs/$feature/handoff.md"
   summary="- Updated specs/$feature/handoff.md with current phase, completed work, pending work, blockers, and the advisory next step"
fi

files_read_block=$(join_paths_as_bullets "${files_read[@]}")

"$SCRIPT_DIR/print_handoff_response_schema.sh" \
   --status completed \
   --feature "$feature" \
   --scope "$scope" \
   --summary "$summary" \
   --files-changed "$files_changed" \
   --files-read "$files_read_block" \
   --missing-prerequisites "- none" \
   --contract-violations "- none" \
   --blockers "$blockers" \
   --unresolved-questions "$unresolved_questions" \
   --drift "$drift" \
   --evidence "$(merge_blocks '- Read feature artifacts and derived handoff state from durable files; no tests run' "$review_evidence")" \
   --recommended-next-phase "$recommended_next_phase" \
   --recommended-next-subagent "$recommended_next_subagent" \
   --notes "$(merge_blocks '- Routing fields are advisory only; orchestrator keeps final routing authority' "$review_stale_artifacts")"