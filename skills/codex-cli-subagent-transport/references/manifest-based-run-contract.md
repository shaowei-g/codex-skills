# Manifest-Based Run Contract

Use this reference when a caller needs deterministic delegated run artifacts from Codex CLI.

## Goal

Make every delegated Codex CLI run readable from the repository workspace without guessing where logs or outputs were written.

The caller should define the run-artifact location up front and then read exactly those declared paths.

## Required Rule

Do not run delegated Codex CLI transport in opaque temp locations such as `/tmp/...` when the caller will need to read the result afterward.

Instead, materialize a repo-local run directory with:

- `bash ./scripts/run_codex_cli_subagent.sh`

## Repo-Local Run Artifacts

Default run root:

- `<repo>/.codex/codex-cli-subagent-runs/<feature>/<phase>-<subagent>-<run-id>/`

Each run must materialize:

- `prompt.md`
- `response.md`
- `exec.log`
- `manifest.env`
- `manifest.json`

Authoritative interpretation:

- `manifest.json` or `manifest.env` is the locator contract
- `response.md` is the only authoritative delegated payload
- `exec.log` is diagnostic only

## Invocation Rule

Preferred invocation pattern:

```bash
bash ./scripts/run_codex_cli_subagent.sh \
  --repo-root /abs/path/to/repo \
  --feature <feature-slug> \
  --phase <assigned-phase> \
  --subagent <assigned-subagent> \
  --prompt-file /abs/path/to/prompt.md
```

The script prints shell-escaped assignments such as:

- `RUN_DIR=...`
- `RESPONSE_FILE=...`
- `EXEC_LOG=...`
- `MANIFEST_JSON=...`
- `EXIT_CODE=...`

The caller should read the manifest or returned path values directly. Do not glob for temp files and do not rely on workspace search to discover the run directory.

## Result Collection Rule

After the delegated execution finishes:

1. read `manifest.json` or `manifest.env`
2. read `response.md`
3. let the caller validate `response.md`
4. use `exec.log` only if the delegated payload is missing or malformed

Blocked classification belongs to the caller, but these conditions typically indicate transport failure:

- `response.md` is missing, unreadable, or empty after the single delegated attempt
- `codex exec` exits nonzero and no authoritative `response.md` exists

## Forbidden Patterns

Do not:

- write the delegated run only to `/tmp` and then try to rediscover it later
- search the workspace for `/tmp/.../response.md`
- infer the authoritative result from `exec.log` when `response.md` is missing
- run a smoke test or a second delegated attempt inside the same bounded caller run
- mix caller-specific routing or acceptance rules into this transport contract
