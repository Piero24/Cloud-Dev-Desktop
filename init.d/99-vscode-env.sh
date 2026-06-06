#!/usr/bin/with-contenv bash
# ================================================================
# Cloud Dev Stack — VSCode container init script
# /config, /projects, and /shared are the same volumes as desktop.
# Shell config, git, nvm, npm, env vars — all shared via /config.
# This script only handles code-server-specific setup.
# ================================================================

USER_HOME=$(getent passwd 1000 | cut -d: -f6)
[ -z "$USER_HOME" ] && USER_HOME=/config

# ---- Shared VS Code extensions ----
# Both containers use the same extensions & settings via /shared
CS_DATA="$USER_HOME/.local/share/code-server"
SHARED_EXT="/shared/code-server/extensions"
SHARED_USER="/shared/code-server/User"

mkdir -p "$SHARED_EXT" "$SHARED_USER"

# Migrate existing extensions to shared (first boot only)
if [ -d "$CS_DATA/extensions" ] && [ ! -L "$CS_DATA/extensions" ] && [ -z "$(ls -A "$SHARED_EXT" 2>/dev/null)" ]; then
    cp -r "$CS_DATA/extensions"/* "$SHARED_EXT/" 2>/dev/null || true
fi
if [ -d "$CS_DATA/User" ] && [ ! -L "$CS_DATA/User" ] && [ -z "$(ls -A "$SHARED_USER" 2>/dev/null)" ]; then
    cp -r "$CS_DATA/User"/* "$SHARED_USER/" 2>/dev/null || true
fi

# Replace local dirs with symlinks to shared
mkdir -p "$CS_DATA"
rm -rf "$CS_DATA/extensions" "$CS_DATA/User"
ln -sf "$SHARED_EXT" "$CS_DATA/extensions"
ln -sf "$SHARED_USER" "$CS_DATA/User"

echo "[vscode-init] Extensions & settings shared via /shared"
echo "[vscode-init] Shell, git, nvm, packages all from desktop's /config"
