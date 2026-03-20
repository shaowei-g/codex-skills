#!/usr/bin/env python3
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path
from typing import Any

COMMON_REQUIRED = [
    "phase",
    "status",
    "gate",
    "approved_by_orchestrator",
    "last_gate_check",
]

ARTIFACT_RULES = {
    "spec.md": {
        "phase": "specification",
        "required": COMMON_REQUIRED,
    },
    "plan.md": {
        "phase": "planning",
        "required": COMMON_REQUIRED + ["execution_ready"],
    },
    "tasks.md": {
        "phase": "task-decomposition",
        "required": COMMON_REQUIRED + ["tasking_gate"],
    },
    "implementation-status.md": {
        "phase": "implementation",
        "required": COMMON_REQUIRED + ["completed_task_ids", "verification_commands"],
    },
}

STATUS_VALUES = {"draft", "ready", "accepted", "superseded"}
GATE_VALUES = {"pending", "passed", "failed"}
TASKING_GATE_VALUES = {"pending", "passed", "failed"}


class MarkerValidationError(Exception):
    pass


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Validate artifact acceptance markers for a feature directory."
    )
    parser.add_argument("feature_path", help="Path to specs/<feature>")
    parser.add_argument(
        "--require-markers",
        action="store_true",
        help="Fail when an existing tracked workflow artifact lacks YAML front matter.",
    )
    return parser.parse_args()


def split_front_matter(text: str) -> tuple[str | None, str]:
    if not text.startswith("---\n"):
        return None, text
    match = re.match(r"^---\n(.*?)\n---\n?(.*)$", text, re.DOTALL)
    if not match:
        return None, text
    return match.group(1), match.group(2)


def parse_scalar(raw: str) -> Any:
    value = raw.strip()
    if value == "true":
        return True
    if value == "false":
        return False
    if value == "null":
        return None
    if re.fullmatch(r"-?\d+", value):
        try:
            return int(value)
        except ValueError:
            return value
    if (value.startswith('"') and value.endswith('"')) or (value.startswith("'") and value.endswith("'")):
        return value[1:-1]
    return value


def parse_front_matter(text: str) -> dict[str, Any]:
    front_matter, _ = split_front_matter(text)
    if front_matter is None:
        return {}

    data: dict[str, Any] = {}
    current_key: str | None = None
    for raw_line in front_matter.splitlines():
        line = raw_line.rstrip()
        if not line.strip():
            continue
        if line.startswith("  - "):
            if current_key is None:
                raise MarkerValidationError("list item appeared before a key")
            data.setdefault(current_key, [])
            if not isinstance(data[current_key], list):
                raise MarkerValidationError(f"key '{current_key}' cannot mix scalar and list values")
            data[current_key].append(parse_scalar(line[4:]))
            continue
        if ":" not in line:
            raise MarkerValidationError(f"invalid front matter line: {line}")
        key, remainder = line.split(":", 1)
        key = key.strip()
        remainder = remainder.strip()
        current_key = key
        if remainder == "":
            data[key] = []
        else:
            data[key] = parse_scalar(remainder)
    return data


def normalized_bool(value: Any) -> str:
    if value is True:
        return "true"
    if value is False:
        return "false"
    if value is None:
        return "null"
    return str(value)


def is_accepted(meta: dict[str, Any]) -> bool:
    return (
        meta.get("status") == "accepted"
        and meta.get("gate") == "passed"
        and meta.get("approved_by_orchestrator") is True
        and meta.get("last_gate_check") not in (None, "")
    )


def validate_required_keys(path: Path, meta: dict[str, Any], required: list[str], errors: list[str]) -> None:
    for key in required:
        if key not in meta:
            errors.append(f"{path}: missing required marker '{key}'")
            continue
        value = meta[key]
        if value == "" or value == []:
            errors.append(f"{path}: marker '{key}' must not be empty")


def validate_marker_values(path: Path, filename: str, expected_phase: str, meta: dict[str, Any], errors: list[str]) -> None:
    if meta.get("phase") not in (None, expected_phase):
        errors.append(f"{path}: phase should be '{expected_phase}', got '{meta.get('phase')}'")

    status = meta.get("status")
    if status is not None and status not in STATUS_VALUES:
        errors.append(f"{path}: invalid status '{status}'")

    gate = meta.get("gate")
    if gate is not None and gate not in GATE_VALUES:
        errors.append(f"{path}: invalid gate '{gate}'")

    approved = meta.get("approved_by_orchestrator")
    if approved is not None and not isinstance(approved, bool):
        errors.append(
            f"{path}: approved_by_orchestrator must be true or false, got '{normalized_bool(approved)}'"
        )

    if filename == "plan.md":
        execution_ready = meta.get("execution_ready")
        if execution_ready is not None and not isinstance(execution_ready, bool):
            errors.append(f"{path}: execution_ready must be true or false")
    if filename == "tasks.md":
        tasking_gate = meta.get("tasking_gate")
        if tasking_gate is not None and tasking_gate not in TASKING_GATE_VALUES:
            errors.append(f"{path}: invalid tasking_gate '{tasking_gate}'")
        task_count = meta.get("task_count")
        if task_count is not None and not isinstance(task_count, int):
            errors.append(f"{path}: task_count must be an integer when present")
    if filename == "implementation-status.md":
        completed = meta.get("completed_task_ids")
        if completed is not None and not isinstance(completed, list):
            errors.append(f"{path}: completed_task_ids must be a list")
        verify = meta.get("verification_commands")
        if verify is not None and not isinstance(verify, list):
            errors.append(f"{path}: verification_commands must be a list")

    if status == "accepted":
        if gate != "passed":
            errors.append(f"{path}: accepted artifact must have gate=passed")
        if approved is not True:
            errors.append(f"{path}: accepted artifact must have approved_by_orchestrator=true")
        if meta.get("last_gate_check") in (None, ""):
            errors.append(f"{path}: accepted artifact must have last_gate_check")
        if filename == "plan.md" and meta.get("execution_ready") is not True:
            errors.append(f"{path}: accepted plan.md should have execution_ready=true")
        if filename == "tasks.md" and meta.get("tasking_gate") != "passed":
            errors.append(f"{path}: accepted tasks.md should have tasking_gate=passed")
        if filename == "implementation-status.md":
            if not meta.get("completed_task_ids"):
                errors.append(f"{path}: accepted implementation-status.md requires completed_task_ids")
            if not meta.get("verification_commands"):
                errors.append(f"{path}: accepted implementation-status.md requires verification_commands")


def validate_artifact(path: Path, filename: str, require_markers: bool, errors: list[str]) -> dict[str, Any]:
    if not path.exists():
        return {}

    text = path.read_text(encoding="utf-8")
    front_matter, _ = split_front_matter(text)
    if front_matter is None:
        if require_markers:
            errors.append(f"{path}: missing YAML front matter")
        return {}

    try:
        meta = parse_front_matter(text)
    except MarkerValidationError as exc:
        errors.append(f"{path}: {exc}")
        return {}

    rule = ARTIFACT_RULES[filename]
    validate_required_keys(path, meta, rule["required"], errors)
    validate_marker_values(path, filename, rule["phase"], meta, errors)
    return meta


def main() -> int:
    args = parse_args()
    feature_dir = Path(args.feature_path)
    if not feature_dir.exists():
        print(f"ERROR: feature path not found: {feature_dir}", file=sys.stderr)
        return 2
    if not feature_dir.is_dir():
        print(f"ERROR: feature path is not a directory: {feature_dir}", file=sys.stderr)
        return 2

    errors: list[str] = []
    metas: dict[str, dict[str, Any]] = {}

    for filename in ARTIFACT_RULES:
        metas[filename] = validate_artifact(feature_dir / filename, filename, args.require_markers, errors)

    spec_ok = is_accepted(metas.get("spec.md", {}))
    plan_ok = is_accepted(metas.get("plan.md", {}))
    tasks_ok = is_accepted(metas.get("tasks.md", {}))
    impl_ok = is_accepted(metas.get("implementation-status.md", {}))

    if plan_ok and not spec_ok:
        errors.append(f"{feature_dir / 'plan.md'}: accepted plan.md cannot outrun unaccepted spec.md")

    if tasks_ok:
        plan_meta = metas.get("plan.md", {})
        if not plan_ok:
            errors.append(f"{feature_dir / 'tasks.md'}: accepted tasks.md requires accepted plan.md")
        if plan_meta.get("execution_ready") is not True:
            errors.append(f"{feature_dir / 'tasks.md'}: accepted tasks.md requires execution_ready=true in plan.md")

    if impl_ok and not tasks_ok:
        errors.append(
            f"{feature_dir / 'implementation-status.md'}: accepted implementation-status.md requires accepted tasks.md"
        )

    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1

    if args.require_markers:
        print(f"OK: artifact acceptance markers are valid for {feature_dir} (strict mode)")
    else:
        print(f"OK: artifact acceptance markers are valid for {feature_dir}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
