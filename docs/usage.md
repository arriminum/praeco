# Usage

## praeco — send a message to Telegram

Send a message to a Telegram chat via a configured bot token and chat ID.

```bash
praeco [--source NAME] "message" [silent]
praeco --version
```

- `--source NAME` — optional. Label identifying the caller (app, site, script). Prefixed to the message as bold `NAME:` followed by a space, so you don't need to repeat it inside the message text. Quote `NAME` if it contains spaces: `--source "hqjury web"`. Also accepts `--source=NAME`. Must come before `message` — praeco stops looking for options at the first non-option argument, so `praeco "message" --source NAME` will NOT apply the source tag.
- `--version` — optional. Prints `praeco <version>` and exits, reading from the `VERSION` file installed alongside the script (override with `$PRAECO_VERSION_FILE`).
- `message` — required. Text to send. Telegram Markdown is supported (`*bold*`, `_italic_`, `` `code` ``, etc). Long messages are fine; Telegram enforces a limit (~4000 characters for a single message).
- `silent` — optional. Literal word `silent`. When present, praeco suppresses Telegram's JSON response from stdout on success. Errors always print to stderr regardless of this flag.

Before attempting to send, praeco always prints a `[praeco] hash: <16 hex chars>` line to stderr, regardless of the `silent` flag. This is the same value logged as `hash=` in [docs/audit.md](audit.md), so you can match a terminal run to its log line when debugging without praeco ever storing or printing the message content itself.

Exit status is 0 on success; non-zero if the message could not be sent (missing config, unreachable API, or a non-200 response from Telegram), so it is safe to chain with `&&`/`||` in scripts and cron jobs.

Examples:

```bash
praeco "Backup completed on $(hostname)!"
praeco "Database query failed at $(date)" silent
praeco --source fabius "3 repositories with pending commits"
```

The last example arrives in Telegram as **fabius:** 3 repositories with pending commits (bold source label). A plain `[NAME]` prefix isn't used because Telegram's Markdown parser treats `[...]` as link syntax and silently strips it when there's no following `(url)`.

## praecomail — send an email alert

Send a plain-text email message through `msmtp` (the local MTA) to any recipient.

```bash
praecomail [--source NAME] recipient@domain.com "subject" "message"
praecomail --version
```

- `--source NAME` — optional. Label identifying the caller (app, site, script). Prefixed to the subject as `[NAME]` followed by a space. Quote `NAME` if it contains spaces: `--source "hqjury web"`. Also accepts `--source=NAME`.
- `--version` — optional. Prints `praecomail <version>` and exits, reading from the `VERSION` file installed alongside the script (override with `$PRAECO_VERSION_FILE`).

Recipient, subject, and message are required. Praecomail composes the email with the configured From address (see below) and sends it via `msmtp --timeout=7`, which connects to the local MTA relay.

Exit status is 0 on success; non-zero if msmtp is missing, not installed, or delivery fails.

Examples:

```bash
praecomail ops@example.com "Disk usage warning" "Root partition is at 92% on $(hostname)."
praecomail --source fabius ops@example.com "Disk usage warning" "Root partition is at 92% on $(hostname)."
```

The last example arrives with subject `[fabius] Disk usage warning`.

## Configuration

Both commands read `/etc/praeco/.env-telegram` (override with `$PRAECO_ENV_FILE`) and, for `--version`, `/usr/local/lib/praeco/VERSION` (override with `$PRAECO_VERSION_FILE`). See [src/.env-telegram.example](../src/.env-telegram.example) for the full list of variables:

| Variable | Used by | Required | Description |
| --- | --- | --- | --- |
| `PRAECO_TOKEN` | praeco | yes | Telegram bot token |
| `PRAECO_CHAT_ID` | praeco | yes | Destination Telegram chat ID |
| `PRAECOMAIL_FROM` | praecomail | no | From address (default `praeco@<hostname>` if unset) |

The file is installed with mode 640, owned by root:praeco. `install.sh` offers to add the invoking (`sudo`) user to the `praeco` group interactively; accept the prompt, or add a user manually later to let them read the config without `sudo`:

```bash
sudo usermod -aG praeco <username>
```

Log out and back in (or run `newgrp praeco`) for a new group membership to take effect in an already-open shell. A cron job picks up new group membership on its next run without needing a re-login.

## Logging

Both commands log every attempt (success or failure) to `/var/log/praeco/`. See [docs/audit.md](audit.md) for details on log format, retention, and log rotation.

- `praeco.log` — overridable with `$PRAECO_LOG_FILE`.
- `praecomail.log` — overridable with `$PRAECOMAIL_LOG_FILE`.

The log directory is created with the setgid bit (mode 2770, owner root:praeco) so every log file written into it inherits the `praeco` group automatically, and group members can write to it, regardless of which user or cron job invokes the commands.

## Cron examples

Run a backup and notify on failure:

```cron
0 3 * * *  /usr/local/bin/backup.sh || /usr/local/bin/praeco "Backup FAILED on $(hostname)" silent
```

Run a health check and email if it fails:

```cron
0 * * * *  /usr/local/bin/check-uptime.sh || /usr/local/bin/praecomail ops@example.com "Uptime check failed" "The health check on $(hostname) did not pass. Check the server."
```

Run a nightly scan and notify only when there are results:

```cron
0 22 * * *  /usr/local/bin/scan-logs.sh | praeco "$(cat)" silent
```

## When scripts abort

Praeco and praecomail stop with an error message on stderr and exit 1 in these cases:

**praeco:**

- `--version` is passed but the version file is missing or not readable.
- `--source` is passed without a value.
- An unrecognized option (starting with `-`) is passed.
- No message argument given, or it is empty.
- Config file `/etc/praeco/.env-telegram` is missing or not readable.
- `PRAECO_TOKEN` or `PRAECO_CHAT_ID` is not set in the config.
- curl fails to reach the Telegram API.
- Telegram API returns a non-200 HTTP status (e.g. 401 Unauthorized, 400 Bad Request).

**praecomail:**

- `--version` is passed but the version file is missing or not readable.
- `--source` is passed without a value.
- An unrecognized option (starting with `-`) is passed.
- Recipient, subject, or message argument is missing or empty.
- msmtp is not installed or not on PATH.
- msmtp fails to send the email (usually due to MTA misconfiguration).

When there is no error, scripts exit 0, even if no notification was configured (e.g. if `msmtp` is missing but you call praecomail, it fails because you tried to use it; but if praeco is called and no network error occurs, it succeeds).

## Make targets

The repository includes a `Makefile` for building, checking, and installing the scripts. Run `make help` to list them.

- `make help` — list all available targets (default goal).
- `make lint` — lint `src/praeco` and `src/praecomail` with `shellcheck`.
- `make dist` — build `dist/praeco-<version>.zip` for distribution (runs lint first).
- `make install` — build, then install to `/usr/local/lib/praeco` with symlinks in `/usr/local/bin` (needs `sudo`).
- `make clean` — remove the `dist/` build artifacts.
