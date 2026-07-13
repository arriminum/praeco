# Releasing

Praeco is not yet a Git repository — releases are manual version bumps and zip builds. Once version control is added, use Git tags to track releases.

## Release checklist

Before releasing a new version:

1. **Update VERSION** to the new semver (e.g. `0.1.0`). See [AGENTS.md](AGENTS.md) under "Versioning" for the rules (MAJOR/MINOR/PATCH).
2. **Update CHANGELOG.md.** Move entries from `[Unreleased]` into a new dated version section (e.g. `## [0.1.0] — 2026-07-12`). Keep the format consistent with existing entries.
3. **Update documentation** if behavior changed: `docs/usage.md`, `README.md`, `AGENTS.md`.
4. **Run `make lint`.** Shellcheck must pass with no warnings.
5. **Build the package:** `make dist`. This produces `dist/praeco-<version>.zip`.
6. **Test the install on a sandbox machine** (VM or container):

   ```bash
   unzip dist/praeco-<version>.zip
   cd praeco
   sudo make install
   sudo vim /etc/praeco/.env-telegram  # add real Telegram credentials for testing only
   praeco "Test message from $(hostname)"
   tail /var/log/praeco/praeco.log
   ```

   Verify the message arrives, the log entry is correct, and `make install` can be run again without errors (idempotency).

7. **Archive the zip:** Keep `dist/praeco-<version>.zip` somewhere safe, or tag it in your deployment system. This becomes the distributable for other servers.

## Deploying to a new server

Once you have the zip:

```bash
scp dist/praeco-<version>.zip user@server:/tmp/
ssh user@server
cd /tmp && unzip praeco-<version>.zip && cd praeco
sudo make install
sudo vim /etc/praeco/.env-telegram
praeco "release <version> installed on $(hostname)"
```

`make install` is idempotent, so re-running it on a server that already has praeco upgrades the scripts without overwriting the existing config or re-running the setup steps.

To verify the installation:

```bash
praeco --version 2>&1 || echo "(no version flag yet)"
ls -la /usr/local/bin/praeco /usr/local/bin/praecomail
cat /etc/praeco/.env-telegram
tail -f /var/log/praeco/praeco.log
```

## When this becomes a Git repository

Once version control is added:

1. After updating `VERSION` and `CHANGELOG.md`, commit:

   ```bash
   git add VERSION CHANGELOG.md [other updated files]
   git commit -m "Release 0.1.0: description of changes"
   ```

2. Create an **annotated Git tag** with the version (always prefix with `v`):

   ```bash
   git tag -a v0.1.0 -m "Version 0.1.0"
   ```

3. Push the tag to the remote:

   ```bash
   git push origin v0.1.0
   ```

4. Create a **GitHub Release** from the tag (web UI or `gh release create`):
   - Paste the relevant section from `CHANGELOG.md` as the release description.
   - Optionally attach `dist/praeco-<version>.zip` as a build artifact.

**Tagging rule:** Always use `v` + version (e.g. `v0.1.0`, `v1.0.0`). This is the Git and GitHub convention for releases.
