# Audit logging

Praeco and praecomail each keep a plain-text log of every send attempt, success or failure. There is no external logging service involved — only a flat file plus standard Linux `logrotate`, configured automatically by `install.sh`.

## Location

Logs are written to `/var/log/praeco/`:

```
/var/log/praeco/praeco.log
/var/log/praeco/praecomail.log
```

Both scripts accept an environment variable override if you need a different path for testing:

- `$PRAECO_LOG_FILE` — praeco log location (default `/var/log/praeco/praeco.log`)
- `$PRAECOMAIL_LOG_FILE` — praecomail log location (default `/var/log/praeco/praecomail.log`)

## Format

One line per event, with timestamp, script name, and status:

```
2026-07-12 14:03:11 [praeco] OK message sent (user=alice source=backup-script id=3f9a1c2b8e7d4f01)
2026-07-12 14:05:44 [praeco] ERROR Telegram API returned HTTP 401 (user=alice source=none id=9c0e2a7b1d4f5601)
2026-07-12 03:00:02 [praecomail] Sending email to ops@example.com (subject: Disk usage warning)
2026-07-12 03:00:03 [praecomail] OK email sent to ops@example.com
```

Message *contents* are never logged, only metadata: timestamp, status, recipient/subject for praecomail, and for praeco the calling user (`user=`), the `--source` label if any (`source=none` when omitted), and a random 16-character transaction id (`id=`), generated fresh from `/dev/urandom` on every call. The id is not derived from the message, user, or source — it exists purely to let you find the exact log line for a specific run (e.g. by printing it in a script and grepping for it later), even when the same alert text is sent repeatedly or from multiple sources. This keeps the log useful for auditing delivery and troubleshooting without ever storing or exposing the message content itself.

## Permissions

`/var/log/praeco` is created with mode 2770 (setgid) and owned by root:praeco. This means every log file written into it automatically inherits the `praeco` group and group members can write to it, regardless of which user or cron job invokes the commands. To let an operator run praeco/praecomail and tail the logs without `sudo`, add their user account to the `praeco` group:

```bash
sudo usermod -aG praeco <username>
```

They can then read the logs without needing `sudo`:

```bash
tail -f /var/log/praeco/praeco.log
```

## Rotation

`install.sh` writes `/etc/logrotate.d/praeco`:

```
/var/log/praeco/*.log {
    weekly
    rotate 8
    compress
    missingok
    notifempty
    create 660 root praeco
}
```

This keeps roughly two months of history (8 weeks × 1 week rotation), compressed after the first rotation. Adjust `rotate`/`weekly` directly in that file if you need a different retention window. Re-running `install.sh` on an existing machine will rewrite this file, so if you customize it, track the change outside of this repo or keep a note in your server's provisioning scripts.
