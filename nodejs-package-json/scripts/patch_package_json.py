#!/usr/bin/env python3

import argparse
import json
import os
import sys
from typing import Any, Dict, List, Tuple


def _is_nextjs(package_json: Dict[str, Any]) -> bool:
    for section in ("dependencies", "devDependencies", "peerDependencies", "optionalDependencies"):
        deps = package_json.get(section)
        if isinstance(deps, dict) and "next" in deps:
            return True

    scripts = package_json.get("scripts")
    if isinstance(scripts, dict):
        for v in scripts.values():
            if isinstance(v, str) and (" next " in f" {v} " or v.strip().startswith("next ")):
                return True
    return False


def _ensure_list_contains(lst: List[Any], item: str) -> bool:
    if item in lst:
        return False
    lst.append(item)
    return True


def _set_script(
    scripts: Dict[str, Any], key: str, value: str, force: bool, warnings: List[str]
) -> bool:
    existing = scripts.get(key)
    if existing is None:
        scripts[key] = value
        return True
    if existing == value:
        return False
    if force:
        scripts[key] = value
        warnings.append(f"Overwrote scripts.{key!s}: {existing!r} -> {value!r}")
        return True
    warnings.append(
        f"Skipped scripts.{key!s} (already set to {existing!r}); rerun with --force to set {value!r}"
    )
    return False


def patch_package_json(path: str, force: bool, nextjs_override: str | None) -> Tuple[bool, List[str]]:
    with open(path, "r", encoding="utf-8") as f:
        data: Dict[str, Any] = json.load(f)

    warnings: List[str] = []
    changed = False

    scripts = data.get("scripts")
    if scripts is None:
        scripts = {}
        data["scripts"] = scripts
        changed = True
    if not isinstance(scripts, dict):
        raise TypeError(f'Expected "scripts" to be an object, got {type(scripts).__name__}')

    if nextjs_override == "true":
        is_nextjs = True
    elif nextjs_override == "false":
        is_nextjs = False
    else:
        is_nextjs = _is_nextjs(data)

    prebuild_value = "rimraf dist .next" if is_nextjs else "rimraf dist"
    changed |= _set_script(scripts, "prebuild", prebuild_value, force, warnings)
    changed |= _set_script(scripts, "postbuild", "tsc-alias", force, warnings)

    pkg = data.get("pkg")
    if pkg is not None:
        if not isinstance(pkg, dict):
            raise TypeError(f'Expected "pkg" to be an object, got {type(pkg).__name__}')

        pkg_scripts = pkg.get("scripts")
        if pkg_scripts is None:
            pkg_scripts = []
            pkg["scripts"] = pkg_scripts
            changed = True
        if not isinstance(pkg_scripts, list):
            raise TypeError(f'Expected "pkg.scripts" to be an array, got {type(pkg_scripts).__name__}')
        changed |= _ensure_list_contains(pkg_scripts, "dist/app/**/*.js")

        pkg_assets = pkg.get("assets")
        if pkg_assets is None:
            pkg_assets = []
            pkg["assets"] = pkg_assets
            changed = True
        if not isinstance(pkg_assets, list):
            raise TypeError(f'Expected "pkg.assets" to be an array, got {type(pkg_assets).__name__}')
        changed |= _ensure_list_contains(pkg_assets, "node_modules/axios/**/*")

        pkg_targets = pkg.get("targets")
        if pkg_targets is None:
            pkg_targets = []
            pkg["targets"] = pkg_targets
            changed = True
        if not isinstance(pkg_targets, list):
            raise TypeError(f'Expected "pkg.targets" to be an array, got {type(pkg_targets).__name__}')
        changed |= _ensure_list_contains(pkg_targets, "node24-linux-x64")

        existing_output_path = pkg.get("outputPath")
        desired_output_path = "./dist-pkg"
        if existing_output_path != desired_output_path:
            pkg["outputPath"] = desired_output_path
            changed = True
            if existing_output_path is not None:
                warnings.append(
                    f"Overwrote pkg.outputPath: {existing_output_path!r} -> {desired_output_path!r}"
                )

    if changed:
        with open(path, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
            f.write("\n")

    return changed, warnings


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Patch a Node.js package.json with recommended scripts (prebuild/postbuild) and optional pkg config."
    )
    parser.add_argument(
        "--path",
        default="package.json",
        help="Path to package.json (default: ./package.json)",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Overwrite existing values when they differ from the recommended defaults.",
    )
    parser.add_argument(
        "--nextjs",
        choices=("auto", "true", "false"),
        default="auto",
        help="Treat the project as Next.js (true/false) or auto-detect (default: auto).",
    )

    args = parser.parse_args()
    path = os.path.abspath(args.path)
    if not os.path.exists(path):
        print(f"File not found: {path}", file=sys.stderr)
        return 2

    try:
        changed, warnings = patch_package_json(path=path, force=args.force, nextjs_override=args.nextjs)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1

    for w in warnings:
        print(f"Warning: {w}", file=sys.stderr)

    if changed:
        print(f"Updated: {path}")
    else:
        print(f"No changes: {path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
