# Changelog

All notable changes to praeco are documented in this file. See [RELEASING.md](RELEASING.md) for the release process.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

(No unreleased changes at this time.)

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
