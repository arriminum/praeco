# AGENTS.md — praeco

Operating guide for AI agents and maintainers working on **praeco**. Read this before changing anything.

## What this project is

Praeco is a pair of small POSIX-shell scripts (`#!/bin/sh`, `set -eu`) for sending operational alerts from scripts, cron jobs, and servers: `praeco` sends a message to Telegram via a bot; `praecomail` sends plain-text email via `msmtp`. Both depend only on `curl`/`msmtp` and are designed to be lightweight, auditable, and easy to drop into cron jobs or other scripts.

Authoritative behavior lives in three places, in this order of trust:

1. `src/praeco` and `src/praecomail` — the actual scripts (source of truth for behavior).
2. [docs/usage.md](docs/usage.md) — the operator-facing reference.
3. [README.md](README.md) — the overview.

If code and docs disagree, the code wins — then fix the docs.

## Repository layout

- `src/praeco` — Telegram messaging script (source of truth).
- `src/praecomail` — email alert script (source of truth).
- `src/.env-telegram.example` — reference configuration file.
- `install.sh` — installer script (idempotent, creates directories/permissions/logrotate).
- `Makefile` — build/check/install targets.
- `VERSION` — repository source of truth for the version.
- `docs/usage.md` — operator-facing reference.
- `docs/audit.md` — logging design and log rotation.
- `README.md` — overview and quick start.
- `CHANGELOG.md`, `RELEASING.md` — change history and release checklist.
- `dist/` — disposable build output (`make dist`); never hand-edit.

## How to work here

- **Check:** `make lint` → `shellcheck -s sh` over all scripts; must pass clean.
- **Build:** `make dist` → runs lint, then creates `dist/praeco-<version>.zip`.
- **Install (real machine):** `sudo make install` → runs `install.sh` on localhost (needs root). Do not use to test; test in a VM or sandbox.
- **Clean:** `make clean` → remove `dist/` build artifacts.

Always run `make lint` before considering a change done.

## Coding conventions

Match the existing style in `src/praeco` and `src/praecomail`:

- **POSIX `sh`, strict mode.** Shebang `#!/bin/sh`; keep `set -eu` at the top. No bashisms: no arrays, `[[ ]]`, `local`, `function` keyword, or `${var,,}` expansion. The scripts must run under `dash`.
- **Quote every expansion** (`"$var"`). Use `command -v` instead of `which`.
- **Fail fast.** Validate arguments before touching the filesystem. On error, print `[<scriptname>] Error: <reason>` to stderr and `exit 1`.
- **English only** for comments, usage/error strings, and log messages.
- **Comments explain *why*, not *what*.** Most lines need none.
- **Errors always go to stderr**, never stdout, so scripts compose safely in cron/`&&`/`||` chains.

## Behavior contract (do not break)

These are the guarantees documented for operators. Changing any of them is a behavior change that must be reflected in `docs/usage.md` and `README.md`:

**praeco:**

- Sends a single message to Telegram via `PRAECO_TOKEN` and `PRAECO_CHAT_ID`.
- Logs every send attempt (success or failure) to `/var/log/praeco/praeco.log`.
- Exits 0 on success; exits 1 if the config is missing, curl fails, or Telegram returns non-200.
- The `silent` flag suppresses stdout but never affects stderr or exit code.
- Configuration is read from `/etc/praeco/.env-telegram` (overridable with `$PRAECO_ENV_FILE`).

**praecomail:**

- Sends a single email via `msmtp` to a recipient, with a subject and message body.
- Logs every send attempt to `/var/log/praeco/praecomail.log`.
- Reads `PRAECOMAIL_FROM` from the config if present; defaults to `praeco@<hostname>`.
- Exits 0 on success; exits 1 if msmtp is missing, not installed, or delivery fails.
- Configuration is read from `/etc/praeco/.env-telegram` (overridable with `$PRAECO_ENV_FILE`).

**install.sh:**

- Idempotent. Running it multiple times on the same machine upgrades the installed scripts in place without overwriting an existing config file.
- Installs scripts to `/usr/local/lib/praeco/`, creates symlinks in `/usr/local/bin/`.
- Creates a `praeco` group and sets directory permissions so any user in that group can read the config without `sudo`.
- Configures `/etc/logrotate.d/praeco` for log rotation (weekly, 8 rotations).
- Never overwrites an existing `/etc/praeco/.env-telegram` on re-run.
- Checks for required dependencies (`curl`); warns if optional ones (`msmtp`) are missing.

## Safety rules for agents

- Treat `dist/` as disposable output; do not hand-edit it.
- Never turn `praeco` or `praecomail` into something that modifies the configuration file or creates new system resources (it can log; it cannot write config).
- Never hardcode a real username, domain, API token, or email address into any script — these ship to other servers via `make dist`.
- Do not run `install.sh` to test a change on a real machine. It mutates `/etc`, `/var/log`, `/usr/local`, and the system group database. Review the diff instead, or test in a sandbox/VM.
- Do not send real Telegram/email messages while developing. Stub the curl/msmtp calls or test in isolation.

## Versioning

Praeco follows [Semantic Versioning 2.0.0](https://semver.org/spec/v2.0.0.html) (`MAJOR.MINOR.PATCH`, each part a non-negative integer):

- **MAJOR** — incompatible change to the command-line interface, the behavior contract, or the configuration format (e.g. changing the env file path, the log format, or adding a required new config variable).
- **MINOR** — new, backward-compatible functionality (e.g. a new optional config variable, a new output format option, or a new script).
- **PATCH** — backward-compatible bug fix or small change (e.g. fixing a quoting bug, improving error messages, or fixing log rotation).

The version lives in the `VERSION` file (repository source of truth); there is no version embedded in the scripts.

**On every change to `src/praeco` or `src/praecomail`:**

1. Bump `VERSION` per the rules above.
2. Add a `CHANGELOG.md` entry (move it out of `[Unreleased]` into a dated version section with today's date).
3. Run `make lint` — it must pass (shellcheck).
4. Update `docs/usage.md` and `README.md` if behavior changed.

## Documentation duties

Any behavior change **must** update, in the same change:

- `VERSION` (bump).
- `CHANGELOG.md` (new entry for the version).
- `docs/usage.md` (resolution order, arg handling, abort conditions, output, config variables).
- `README.md` (overview, examples, requirements) if the summary shifts.
- `AGENTS.md` (this file), if a convention or contract changes.

Keep all `.md` text in **English**, written as an SOP with imperative/infinitive verbs ("Send…", "Read…", "Check…", "Log…", "Fail…").

## Markdown formatting

Do not hard-wrap Markdown paragraphs. Keep each paragraph on a single line unless there is an explicit semantic reason to add a line break, such as a list item, code block, table, heading, or intentionally separated paragraph.
