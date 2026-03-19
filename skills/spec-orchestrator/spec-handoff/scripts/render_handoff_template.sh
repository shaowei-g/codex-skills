#!/usr/bin/env bash
set -euo pipefail

usage() {
	cat <<'EOF'
Usage:
	render_handoff_template.sh \
		--phase <phase> \
		--completed <text> \
		--pending <text> \
		--blockers <text> \
		--next-step <text>

Arguments are rendered directly into the shared handoff markdown template.
For list values, pass newline-separated bullet lines or a plain string.
EOF
}

phase=""
completed="none"
pending="none"
blockers="none"
next_step="none"

while [[ $# -gt 0 ]]; do
	case "$1" in
		--phase)
			phase=${2-}
			shift 2
			;;
		--completed)
			completed=${2-}
			shift 2
			;;
		--pending)
			pending=${2-}
			shift 2
			;;
		--blockers)
			blockers=${2-}
			shift 2
			;;
		--next-step)
			next_step=${2-}
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

if [[ -z "$phase" ]]; then
	echo "Missing required argument: --phase" >&2
	usage >&2
	exit 1
fi

printf '## Current Phase\n\n- %s\n\n' "$phase"
printf '## Completed Work\n\n%s\n\n' "$completed"
printf '## Pending Work\n\n%s\n\n' "$pending"
printf '## Blockers\n\n%s\n\n' "$blockers"
printf '## Recommended Next Step\n\n%s\n' "$next_step"