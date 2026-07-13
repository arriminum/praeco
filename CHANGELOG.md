# Changelog

All notable changes to praeco are documented in this file. See [RELEASING.md](RELEASING.md) for the release process.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

(No unreleased changes at this time.)

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
