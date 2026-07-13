# praeco

**Praeco** is a pair of small, auditable POSIX-shell scripts for sending operational alerts from cron jobs and server scripts. Point them at your Telegram bot and email address, and use them to notify yourself when backups fail, disk space runs low, or anything else needs attention.

- **`praeco`** — send a message to Telegram via a bot.
- **`praecomail`** — send a plain-text email via `msmtp`.

Both are lightweight, have no external dependencies beyond `curl`/`msmtp`, and are designed to be easy to drop into cron jobs or server scripts without fuss.

This tool is maintained for and used by [Arriminum](https://arriminum.com) projects.

## What it does

`praeco` sends a message to a Telegram chat through a configured bot token and chat ID. `praecomail` sends a message via the local `msmtp` MTA to any recipient. Both scripts:

- Log every send attempt (success or failure) to `/var/log/praeco/`.
- Exit 0 on success; exit 1 on any error (config missing, network failure, delivery failure).
- Are safe to chain in cron jobs and shell `&&`/`||` expressions.

Example:

```bash
/usr/local/bin/backup.sh || praeco "Backup FAILED on $(hostname)" silent
```

See [docs/usage.md](docs/usage.md) for the full command reference.

## Basic usage

```bash
praeco "Backup completed on $(hostname)!"              # send Telegram message
praecomail ops@example.com "Subject" "Message body"    # send email
```

Both commands read configuration from `/etc/praeco/.env-telegram`. After installing (see below), edit that file to add your Telegram token and chat ID:

```bash
sudo vim /etc/praeco/.env-telegram
```

Check the installed version at any time:

```bash
praeco --version
```

## Notifications

- **Telegram (`praeco`).** Send a message to a Telegram chat through `/usr/local/bin/praeco` by setting `PRAECO_TOKEN` and `PRAECO_CHAT_ID` in the config. Telegram Markdown is supported.
- **Email (`praecomail`).** Send a message via `msmtp` (the local MTA) by running `/usr/local/bin/praecomail recipient@domain.com "subject" "message"`. The From address is configurable via `PRAECOMAIL_FROM` in the config; it defaults to `praeco@<hostname>`.

## Running from cron

Praeco is well suited to unattended cron jobs that only reach you when something fails:

```cron
0 3 * * *  /usr/local/bin/backup.sh || /usr/local/bin/praeco "Backup FAILED on $(hostname)" silent
0 9 * * *  /usr/local/bin/check-disk.sh || /usr/local/bin/praecomail ops@example.com "Disk warning" "$(df -h /)"
```

See [docs/usage.md](docs/usage.md) for more examples.

## Installation

Praeco ships as a small zip built with `make dist`. On the target server:

```bash
unzip praeco-<version>.zip
cd praeco
sudo make install
```

`install.sh`:

- Checks for required dependencies (`curl`; warns if `msmtp` is missing).
- Installs the scripts to `/usr/local/lib/praeco` and creates symlinks in `/usr/local/bin`.
- Creates `/etc/praeco/.env-telegram` from the example file, without overwriting an existing one.
- Creates `/var/log/praeco` and configures logrotate to keep roughly two months of history.
- Is safe to re-run to upgrade an existing install.

To uninstall:

```bash
sudo rm -f /usr/local/bin/praeco /usr/local/bin/praecomail
sudo rm -rf /usr/local/lib/praeco /etc/praeco /var/log/praeco
```

## Requirements

- **curl** (for `praeco`).
- **msmtp**, configured for your outgoing mail relay (for `praecomail`).
- A **Telegram bot token and chat ID** — see the [Telegram Bot API docs](https://core.telegram.org/bots#how-do-i-create-a-bot).

## Safety

- **Read-only and auditable.** Both scripts send messages; they never modify the configuration file or create new system resources.
- **Fail fast.** Exit non-zero on any error (missing config, network failure, delivery failure), so you can chain scripts safely.
- **Log every attempt.** See [docs/audit.md](docs/audit.md) for logging design and rotation policy.
- **Proper permissions.** The config file is mode 640 and readable only by root and the `praeco` group, so you can add operators to that group to let them view logs without `sudo`.

## Versioning

Praeco follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html). The current version lives in the [VERSION](VERSION) file. See [CHANGELOG.md](CHANGELOG.md) for the history of changes, and [RELEASING.md](RELEASING.md) for the step-by-step release process.

## Make targets

Use the included [Makefile](Makefile) to build, check, and install the scripts.

- `make help` — list all available targets (default).
- `make lint` — run shellcheck over all scripts.
- `make dist` — build `dist/praeco-<version>.zip` for distribution.
- `make install` — install the scripts to `/usr/local/lib/praeco` and symlink them (needs `sudo`).
- `make clean` — remove the `dist/` build artifacts.

## Development and contributing

See [AGENTS.md](AGENTS.md) for conventions when contributing, and [docs/usage.md](docs/usage.md) for the operator-facing reference.

## Repository

```txt
git@github.com:arriminum/praeco.git
```

## License

Proprietary — © Arriminum. Internal use only.
