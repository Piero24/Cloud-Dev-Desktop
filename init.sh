#!/usr/bin/with-contenv bash
# ================================================================
# Cloud Dev Stack — Container init script
# Runs on every container boot (linuxserver cont-init.d hook)
# Installs system packages + SSH + nvm + Node + Claude Code
# Forces all package managers to install into /config (persistent)
# ================================================================

# ---- User Setup ----
# We use the default linuxserver user 'abc' for everything to ensure maximum
# compatibility with the pre-configured desktop and services.
USER="abc"
echo "[cloud-dev] Running as default user: '$USER'"

# ---- Helper: add line to file if not already present ----
add_line() {
    local line="$1" file="$2"
    if [ -f "$file" ] && grep -qF "$line" "$file" 2>/dev/null; then
        return 0
    fi
    echo "$line" >> "$file"
}

# ---- System packages (reinstalled every boot — fast) ----
echo "[cloud-dev] Installing system packages..."
apt-get update -qq
apt-get install -y -qq \
    openssh-server \
    build-essential \
    python3-pip \
    python3-venv \
    default-jdk \
    git \
    curl \
    docker.io \
    tmux \
    zsh \
    nano

# ---- VS Code (desktop, inside the container) ----
if ! command -v code &>/dev/null; then
    echo "[cloud-dev] Installing VS Code..."
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /etc/apt/trusted.gpg.d/microsoft.gpg
    echo "deb [arch=amd64] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list
    apt-get update -qq
    apt-get install -y -qq code
    echo "[cloud-dev] VS Code installed"
else
    echo "[cloud-dev] VS Code already installed, skipping."
fi

# ---- SSH server ----
echo "[cloud-dev] Configuring SSH..."
sed -i 's/#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
# Allow custom env vars from SSH clients (for tmux auto-attach + timeout)
if ! grep -q "AcceptEnv TMUX_AUTO" /etc/ssh/sshd_config 2>/dev/null; then
    echo "AcceptEnv TMUX_AUTO" >> /etc/ssh/sshd_config
    echo "AcceptEnv TMUX_TIMEOUT" >> /etc/ssh/sshd_config
fi

# Set user password for SSH (runs every boot — /etc/shadow is not persisted)
if [ -n "$SUDO_PASSWORD" ] && [ "$SUDO_PASSWORD" != "CHANGE_ME_SUDO_PASSWORD" ]; then
    printf '%s:%s' "$USER" "$SUDO_PASSWORD" | chpasswd 2>/dev/null && \
        echo "[cloud-dev] SSH password set for $USER" || \
        echo "[cloud-dev] ERROR: chpasswd failed for $USER"
elif [ -z "$SUDO_PASSWORD" ]; then
    echo "[cloud-dev] WARNING: SUDO_PASSWORD is empty — SSH password NOT set!"
    echo "[cloud-dev] Check that SUDO_PASSWORD is set in compose.yaml"
else
    echo "[cloud-dev] WARNING: SUDO_PASSWORD is still the placeholder — SSH password NOT set!"
fi

service ssh start
echo "[cloud-dev] SSH server started."

# ---- nvm + Node LTS (persists to /config/.nvm) ----
if [ ! -d /config/.nvm ]; then
    echo "[cloud-dev] Installing nvm + Node LTS..."
    su - "$USER" -c 'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash'
    su - "$USER" -c 'export NVM_DIR="$HOME/.nvm" && [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" && nvm install --lts'
else
    echo "[cloud-dev] nvm already installed, skipping."
fi

# ---- code-server (VS Code in browser, inside desktop) ----
# Shares extensions with the vscode container via /shared
# Runs in background on port 9443 — access from desktop browser at localhost:9443
if [ ! -f /usr/local/bin/code-server ]; then
    echo "[cloud-dev] Installing code-server..."
    export HOME=/root
    curl -fsSL https://code-server.dev/install.sh | sh -s -- --method standalone
    echo "[cloud-dev] code-server binary installed"
fi

# Start code-server if not already running
if ! pgrep -f "code-server.*9443" >/dev/null 2>&1; then
    mkdir -p /config/.config/code-server
    cat > /config/.config/code-server/config.yaml << CSYAML
bind-addr: 127.0.0.1:9443
auth: password
password: ${PASSWORD}
cert: false
CSYAML
    su - "$USER" -c "nohup /usr/local/bin/code-server --bind-addr 127.0.0.1:9443 > /config/.code-server.log 2>&1 &"
    echo "[cloud-dev] code-server running on http://localhost:9443 (inside desktop)"
else
    echo "[cloud-dev] code-server already running, skipping."
fi

# ---- npm global prefix → /config (env var, not .npmrc — avoids nvm conflict) ----
su - "$USER" -c 'mkdir -p ~/.npm-global'

# ---- Claude Code ----
if [ -d /config/.nvm ]; then
    if ! su - "$USER" -c 'export NVM_DIR="$HOME/.nvm" && [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" && which claude 2>/dev/null'; then
        echo "[cloud-dev] Installing Claude Code..."
        su - "$USER" -c 'export NVM_DIR="$HOME/.nvm" && [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" && npm install -g @anthropic-ai/claude-code'
    else
        echo "[cloud-dev] Claude Code already installed, skipping."
    fi
fi

# ---- Shell config: force pip/npm/Go to install into /config ----
for rcfile in /config/.bashrc /config/.zshrc; do
    add_line 'export PIP_USER=yes' "$rcfile"
    add_line 'export PIP_BREAK_SYSTEM_PACKAGES=1' "$rcfile"
    add_line 'export GOPATH=~/go' "$rcfile"
    add_line 'export NVM_DIR="$HOME/.nvm"' "$rcfile"
    add_line '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' "$rcfile"
    add_line 'export PATH=~/go/bin:~/.npm-global/bin:$PATH' "$rcfile"
done

# ---- .bash_profile: SSH login shells source this, NOT .bashrc ----
cat > "/config/.bash_profile" << 'BASH_PROFILE'
# Source .bashrc for login shells (SSH)
if [ -f ~/.bashrc ]; then
    . ~/.bashrc
fi
BASH_PROFILE

# ---- Claude Code API env vars (from Compose env) ----
# Written fresh on every boot — edit compose.yaml to change values
for dsrcfile in /config/.bashrc /config/.zshrc; do
    sed -i '/^# >>> Claude Code/,/^# <<< Claude Code/d' "$dsrcfile" 2>/dev/null
    cat >> "$dsrcfile" << CLAUDECODE
# >>> Claude Code (set from Compose env — edit compose.yaml to change)
$( [ -n "${ANTHROPIC_BASE_URL}" ] && echo "export ANTHROPIC_BASE_URL=${ANTHROPIC_BASE_URL}" )
export ANTHROPIC_AUTH_TOKEN=${ANTHROPIC_AUTH_TOKEN:-CHANGE_ME_ANTHROPIC_KEY}
export ANTHROPIC_MODEL=${ANTHROPIC_MODEL:-claude-opus-4-8}
export ANTHROPIC_DEFAULT_OPUS_MODEL=${ANTHROPIC_DEFAULT_OPUS_MODEL:-claude-opus-4-8}
export ANTHROPIC_DEFAULT_SONNET_MODEL=${ANTHROPIC_DEFAULT_SONNET_MODEL:-claude-sonnet-4-6}
export ANTHROPIC_DEFAULT_HAIKU_MODEL=${ANTHROPIC_DEFAULT_HAIKU_MODEL:-claude-haiku-4-5}
export CLAUDE_CODE_SUBAGENT_MODEL=${CLAUDE_CODE_SUBAGENT_MODEL:-claude-haiku-4-5}
export CLAUDE_CODE_EFFORT_LEVEL=${CLAUDE_CODE_EFFORT_LEVEL:-max}
# <<< Claude Code
CLAUDECODE
done

# ---- Write env vars to /shared so vscode container picks them up ----
cat > /shared/.cloud-dev-env << SHAREDENV
# Shared env vars — written by desktop init, read by vscode container
$( [ -n "${ANTHROPIC_BASE_URL}" ] && echo "export ANTHROPIC_BASE_URL=${ANTHROPIC_BASE_URL}" )
export ANTHROPIC_AUTH_TOKEN=${ANTHROPIC_AUTH_TOKEN:-CHANGE_ME_ANTHROPIC_KEY}
export ANTHROPIC_MODEL=${ANTHROPIC_MODEL:-claude-opus-4-8}
export ANTHROPIC_DEFAULT_OPUS_MODEL=${ANTHROPIC_DEFAULT_OPUS_MODEL:-claude-opus-4-8}
export ANTHROPIC_DEFAULT_SONNET_MODEL=${ANTHROPIC_DEFAULT_SONNET_MODEL:-claude-sonnet-4-6}
export ANTHROPIC_DEFAULT_HAIKU_MODEL=${ANTHROPIC_DEFAULT_HAIKU_MODEL:-claude-haiku-4-5}
export CLAUDE_CODE_SUBAGENT_MODEL=${CLAUDE_CODE_SUBAGENT_MODEL:-claude-haiku-4-5}
export CLAUDE_CODE_EFFORT_LEVEL=${CLAUDE_CODE_EFFORT_LEVEL:-max}
SHAREDENV
echo "[cloud-dev] Env vars written to /shared/.cloud-dev-env"

# ---- Shared VS Code extensions (via /shared) ----
# Symlinks so both containers use the same extensions & settings
USER_HOME="/home/$USER"
[ ! -d "$USER_HOME" ] && USER_HOME="/config"

CS_DATA="$USER_HOME/.local/share/code-server"
SHARED_EXT="/shared/code-server/extensions"
SHARED_USER="/shared/code-server/User"

mkdir -p "$SHARED_EXT" "$SHARED_USER"

# Migrate local extensions to shared on first boot
if [ -d "$CS_DATA/extensions" ] && [ ! -L "$CS_DATA/extensions" ] && [ -z "$(ls -A "$SHARED_EXT" 2>/dev/null)" ]; then
    cp -r "$CS_DATA/extensions"/* "$SHARED_EXT/" 2>/dev/null || true
fi
if [ -d "$CS_DATA/User" ] && [ ! -L "$CS_DATA/User" ] && [ -z "$(ls -A "$SHARED_USER" 2>/dev/null)" ]; then
    cp -r "$CS_DATA/User"/* "$SHARED_USER/" 2>/dev/null || true
fi

# Replace with symlinks to shared
mkdir -p "$CS_DATA"
rm -rf "$CS_DATA/extensions" "$CS_DATA/User"
ln -sf "$SHARED_EXT" "$CS_DATA/extensions"
ln -sf "$SHARED_USER" "$CS_DATA/User"
echo "[cloud-dev] Code-server extensions & settings shared via /shared"

# ---- Git / GitHub config (from Compose env) ----
if [ -n "${GIT_USER_NAME}" ] && [ "${GIT_USER_NAME}" != "CHANGE_ME_GIT_NAME" ]; then
    su - "$USER" -c "git config --global user.name '${GIT_USER_NAME}'"
    su - "$USER" -c "git config --global user.email '${GIT_USER_EMAIL}'"
    echo "[cloud-dev] Git configured: ${GIT_USER_NAME} <${GIT_USER_EMAIL}>"
fi

if [ -n "${GITHUB_TOKEN}" ] && [ "${GITHUB_TOKEN}" != "CHANGE_ME_GITHUB_TOKEN" ]; then
    su - "$USER" -c "git config --global url.'https://oauth2:${GITHUB_TOKEN}@github.com/'.insteadOf 'https://github.com/'"
    echo "[cloud-dev] GitHub token configured (fine-grained PAT)"
fi

# ---- Default to /projects on SSH login (not inside tmux) ----
add_line 'if [ -z "$TMUX" ]; then cd /projects; fi' /config/.bashrc
add_line 'if [ -z "$TMUX" ]; then cd /projects; fi' /config/.zshrc

# ---- tmux: auto-attach only when client sets TMUX_AUTO=1 (e.g. iPhone/Termius) ----
# TMUX_TIMEOUT: hours before killing a detached session (-1=never, 0=on detach, N=after N hours)
# Set via Termius env var alongside TMUX_AUTO=1
add_line 'if [ "$TMUX_AUTO" = "1" ] && [ -z "$TMUX" ]; then exec tmux new -A -s main; fi' /config/.bashrc
add_line 'if [ "$TMUX_AUTO" = "1" ] && [ -z "$TMUX" ]; then exec tmux new -A -s main; fi' /config/.zshrc
add_line 'alias ta="tmux new -A -s main"' /config/.bashrc
add_line 'alias ta="tmux new -A -s main"' /config/.zshrc
add_line 'alias tmux-keep="tmux setenv TMUX_KEEP 1 && echo \"Session marked keep — will never be auto-cleaned\""' /config/.bashrc
add_line 'alias tmux-keep="tmux setenv TMUX_KEEP 1 && echo \"Session marked keep — will never be auto-cleaned\""' /config/.zshrc

# ---- tmux cleanup daemon: kills detached sessions after TMUX_TIMEOUT hours ----
cat > /usr/local/bin/tmux-cleanup.sh << 'TMUXCLEANUP'
#!/bin/bash
TIMEOUT="${TMUX_TIMEOUT:--1}"
# -1 = never kill, skip entirely
[ "$TIMEOUT" = "-1" ] && exit 0

echo "[tmux-cleanup] Watching detached sessions (timeout=${TIMEOUT}h)"

while true; do
    sleep 300  # check every 5 minutes
    tmux list-sessions -F '#{session_name} #{session_attached} #{session_activity}' 2>/dev/null | \
    while read name attached activity; do
        if [ "$attached" = "0" ]; then
            # Skip sessions marked with tmux-keep
            keep=$(tmux showenv -t "$name" TMUX_KEEP 2>/dev/null | cut -d= -f2)
            [ "$keep" = "1" ] && continue
            now=$(date +%s)
            idle_hours=$(( (now - activity) / 3600 ))
            if [ "$TIMEOUT" = "0" ] || [ "$idle_hours" -ge "$TIMEOUT" ]; then
                tmux kill-session -t "$name" 2>/dev/null && \
                echo "[tmux-cleanup] Killed session '$name' (detached ${idle_hours}h, limit ${TIMEOUT}h)"
            fi
        fi
    done
done
TMUXCLEANUP
chmod +x /usr/local/bin/tmux-cleanup.sh

# Start the cleanup daemon if not already running (only when TMUX_TIMEOUT is set)
add_line 'if [ -n "$TMUX_TIMEOUT" ] && [ "$TMUX_TIMEOUT" != "-1" ] && ! pgrep -f "tmux-cleanup" >/dev/null 2>&1; then nohup /usr/local/bin/tmux-cleanup.sh > /dev/null 2>&1 & fi' /config/.bashrc
add_line 'if [ -n "$TMUX_TIMEOUT" ] && [ "$TMUX_TIMEOUT" != "-1" ] && ! pgrep -f "tmux-cleanup" >/dev/null 2>&1; then nohup /usr/local/bin/tmux-cleanup.sh > /dev/null 2>&1 & fi' /config/.zshrc

# ---- Force English locale ----
for locfile in /config/.bashrc /config/.zshrc; do
    add_line 'export LANG=en_US.UTF-8' "$locfile"
    add_line 'export LANGUAGE=en_US:en' "$locfile"
    add_line 'export LC_ALL=en_US.UTF-8' "$locfile"
done

# ---- Fix ownership ----
chown -R "$USER:$USER" /config

echo "[cloud-dev] Init complete. SSH is running as '$USER'. nvm, Node, Claude Code are ready."
