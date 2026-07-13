#!/bin/sh
#
# install.sh - install praeco and praecomail on this machine.
#
# Run as root (e.g. `sudo ./install.sh` or via `make install`). Safe to
# re-run: it upgrades the installed scripts in place and never overwrites
# an existing env file. See RELEASING.md for how the distributable
# package is built and docs/usage.md for how to use praeco/praecomail
# afterwards.

set -eu

# shellcheck disable=SC1007
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

LIB_DIR=/usr/local/lib/praeco
BIN_DIR=/usr/local/bin
ENV_DIR=/etc/praeco
ENV_FILE="$ENV_DIR/.env-telegram"
LOG_DIR=/var/log/praeco
LOGROTATE_CONF=/etc/logrotate.d/praeco
GROUP=praeco

fail() {
    echo "[install] Error: $1" >&2
    exit 1
}

if [ "$(id -u)" -ne 0 ]; then
    fail "this script must be run as root (try: sudo ./install.sh)"
fi

echo "[install] Checking dependencies..."

if ! command -v curl >/dev/null 2>&1; then
    fail "curl is required but not installed (install it and re-run)"
fi

if ! command -v msmtp >/dev/null 2>&1; then
    echo "[install] Warning: msmtp is not installed - praecomail will not work until it is (e.g. apt install msmtp)"
fi

for f in praeco praecomail .env-telegram.example VERSION; do
    [ -f "$SCRIPT_DIR/$f" ] || fail "$f not found next to install.sh"
done

echo "[install] Creating group $GROUP..."
if ! getent group "$GROUP" >/dev/null 2>&1; then
    groupadd --system "$GROUP"
fi

echo "[install] Creating directories..."
mkdir -p "$LIB_DIR" "$ENV_DIR" "$LOG_DIR"

echo "[install] Installing scripts to $LIB_DIR..."
cp "$SCRIPT_DIR/praeco" "$SCRIPT_DIR/praecomail" "$LIB_DIR/"
chown root:root "$LIB_DIR/praeco" "$LIB_DIR/praecomail"
chmod 755 "$LIB_DIR/praeco" "$LIB_DIR/praecomail"

echo "[install] Installing version file to $LIB_DIR..."
cp "$SCRIPT_DIR/VERSION" "$LIB_DIR/VERSION"
chown root:root "$LIB_DIR/VERSION"
chmod 644 "$LIB_DIR/VERSION"

echo "[install] Linking commands into $BIN_DIR..."
for cmd in praeco praecomail; do
    target="$BIN_DIR/$cmd"
    if [ -e "$target" ] && [ ! -L "$target" ]; then
        fail "$target already exists and is not a symlink - remove it manually and re-run"
    fi
    ln -sf "$LIB_DIR/$cmd" "$target"
done

echo "[install] Setting up env directory $ENV_DIR..."
if [ ! -f "$ENV_FILE" ]; then
    cp "$SCRIPT_DIR/.env-telegram.example" "$ENV_FILE"
    echo "[install] Created $ENV_FILE - edit it with real credentials before use"
else
    echo "[install] $ENV_FILE already exists - leaving it untouched"
fi
chown root:"$GROUP" "$ENV_FILE"
chmod 640 "$ENV_FILE"
chown root:"$GROUP" "$ENV_DIR"
chmod 750 "$ENV_DIR"

echo "[install] Setting up log directory $LOG_DIR..."
chown root:"$GROUP" "$LOG_DIR"
chmod 2770 "$LOG_DIR"
for logfile in "$LOG_DIR"/*.log; do
    [ -f "$logfile" ] || continue
    chown root:"$GROUP" "$logfile"
    chmod 660 "$logfile"
done

TARGET_USER="${SUDO_USER:-}"
if [ -n "$TARGET_USER" ] && [ "$TARGET_USER" != "root" ] && [ -t 0 ]; then
    if id -nG "$TARGET_USER" 2>/dev/null | tr ' ' '\n' | grep -qx "$GROUP"; then
        echo "[install] User $TARGET_USER is already in the $GROUP group."
    else
        printf '[install] Add user %s to the %s group so it can use praeco/praecomail without sudo? [y/N] ' "$TARGET_USER" "$GROUP"
        read -r REPLY
        case "$REPLY" in
            [yY]*)
                usermod -aG "$GROUP" "$TARGET_USER"
                echo "[install] Added $TARGET_USER to $GROUP. Log out and back in (or run 'newgrp $GROUP') for it to take effect."
                ;;
            *)
                echo "[install] Skipped. Run 'sudo usermod -aG $GROUP <username>' later if needed."
                ;;
        esac
    fi
fi

echo "[install] Configuring logrotate..."
cat >"$LOGROTATE_CONF" <<EOF
$LOG_DIR/*.log {
    weekly
    rotate 8
    compress
    missingok
    notifempty
    create 660 root $GROUP
}
EOF

echo "[install] Done. Installed version: $(cat "$SCRIPT_DIR/VERSION" 2>/dev/null || echo unknown)"
echo "[install] Next steps:"
echo "[install]   1. sudo vim $ENV_FILE"
echo "[install]   2. praeco \"Hello from \$(hostname)\""
echo "[install] See docs/usage.md for full usage and docs/audit.md for log details."
