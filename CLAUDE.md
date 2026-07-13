# CLAUDE.md

Quick reference for AI agents working on praeco. For the full guide, see [AGENTS.md](AGENTS.md).

**Code style:** POSIX `sh`, `set -eu`, quote everything, no bashisms, English only.

**Before committing:** Run `make lint` and verify it passes. Never run `install.sh` to test on a real machine — read the diff instead, or test in a VM.

**Do not:** Hardcode usernames/domains/credentials in scripts or `install.sh`; they ship to other servers via `make dist`. Never modify config files or system state; only send messages and log attempts.

**Keep in sync:** If you change behavior in `src/praeco` or `src/praecomail`, update `VERSION`, `CHANGELOG.md`, `docs/usage.md`, and `README.md` in the same change. See [AGENTS.md](AGENTS.md) under "Documentation duties" for the full list.

**Markdown:** Do not hard-wrap paragraphs. Keep each paragraph on a single line unless there is a semantic reason for a line break (list item, code block, table, heading, intentionally separated paragraph).
