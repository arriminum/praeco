# Changelog

All notable changes to praeco are documented in this file. See [RELEASING.md](RELEASING.md) for the release process.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.4.0] — 2026-07-13

### Added

- praeco: log lines now include the calling user (`user=`), the `--source` label if any (`source=none` when omitted), and a 16-character SHA-256 prefix of the message text (`hash=`), so send attempts can be traced back to a caller and correlated across log lines without ever storing the message content itself.
- praeco: now prints a `[praeco] hash: <16 hex chars>` line to stderr before sending, matching the `hash=` field logged for that attempt, so a terminal run can be matched to its log line during debugging.

### Fixed

- install.sh: `/var/log/praeco` is now created with mode 2770 instead of 2750, and logrotate now recreates rotated logs with mode 660 instead of 640, so non-root members of the `praeco` group can actually write to the log files (previously they could only read them, so `praeco`/`praecomail` failed with "Permission denied" writing to the log after a member ran the commands without `sudo`). Re-run `install.sh` on existing installs to pick up the new permissions.
- praeco: `--source NAME` now prefixes the message with bold `NAME:` text instead of `[NAME]`. Telegram's Markdown parser treats `[NAME]` as link syntax and silently strips the brackets when there's no following `(url)`, so the source tag was never actually visible in delivered messages.
- praeco: the Telegram API response (or its error body) is now followed by a newline when printed, so the shell prompt no longer runs together with the JSON on the same line.

## [0.3.0] — 2026-07-13

### Added

- praeco/praecomail: new `--version` argument that prints the installed version and exits, reading `/usr/local/lib/praeco/VERSION` (override with `$PRAECO_VERSION_FILE`).
- install.sh: now installs the `VERSION` file to `/usr/local/lib/praeco` alongside the scripts, so `--version` works after install.

### Changed

- Makefile: `make dist` now removes all old `.zip` files in `dist/` before building, so only the latest package remains.

## [0.2.0] — 2026-07-13

### Added

- praeco: new optional `--source NAME` (or `--source=NAME`) argument that prefixes the outgoing message with `[NAME]` and a space, so callers can identify themselves without editing the message text.
- praecomail: new optional `--source NAME` (or `--source=NAME`) argument that prefixes the email subject with `[NAME]` and a space.

## [0.1.1] — 2026-07-13

### Added

- install.sh: interactively offers to add the invoking (`sudo`) user to the `praeco` group, so they can read the env file and write logs without `sudo`. Skipped automatically when not run from a TTY or when invoked directly as root.

## [0.1.0] — 2026-07-12

### Added

- Initial release preparation: refactored scripts for production use.
- MIT License: released as open source.

### Changed

- Consolidated env file path from `/etc/telegram-env/.env-telegram` to `/etc/praeco/.env-telegram`.
- Reorganized install.sh: now idempotent, creates dedicated `praeco` group, configures logrotate, checks dependencies at install time.
- Updated praeco: added proper HTTP status checking, error logging, configurable log file, env file validation.
- Updated praecomail: added error handling, msmtp existence check, optional PRAECOMAIL_FROM configuration.

### Fixed

- Fixed install.sh: removed invalid `return 1` at script end (crashes under sh/dash).
- Fixed install.sh: removed hardcoded username from usermod command.
- Fixed praeco: message urlencode to properly handle `&`/`=` in text.
- Fixed praeco/praecomail: both now validate HTTP status and exit non-zero on delivery failure.

### Removed

- Removed `build` script; consolidated into `make dist` target in Makefile.

## [0.0.1] — Initial version (unreleased)

Placeholder for the first release.
