#!/bin/bash
# ================================================================
# Cloud Dev Stack — Container init script
# Runs on every container boot (linuxserver cont-init.d hook)
# Installs system packages + SSH + nvm + Node + Claude Code
# Forces all package managers to install into /config (persistent)
# ================================================================

# ---- Use custom username if set, otherwise default to abc ----
USER="${CUSTOM_USER:-abc}"

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

# ---- SSH server ----
echo "[cloud-dev] Configuring SSH..."
sed -i 's/#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
# Allow custom env vars from SSH clients (for tmux auto-attach + timeout)
if ! grep -q "AcceptEnv TMUX_AUTO" /etc/ssh/sshd_config 2>/dev/null; then
    echo "AcceptEnv TMUX_AUTO" >> /etc/ssh/sshd_config
    echo "AcceptEnv TMUX_TIMEOUT" >> /etc/ssh/sshd_config
fi
echo "$USER:${SUDO_PASSWORD}" | chpasswd
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

# ---- DeepSeek API env vars (for Claude Code) ----
for dsrcfile in /config/.bashrc /config/.zshrc; do
    if ! grep -q "ANTHROPIC_BASE_URL" "$dsrcfile" 2>/dev/null; then
        cat >> "$dsrcfile" << 'DEEPSEEK'
# Claude Code via DeepSeek API
export ANTHROPIC_BASE_URL=https://api.deepseek.com/anthropic
export ANTHROPIC_AUTH_TOKEN=<your DeepSeek API Key>
export ANTHROPIC_MODEL=deepseek-v4-pro[1m]
export ANTHROPIC_DEFAULT_OPUS_MODEL=deepseek-v4-pro[1m]
export ANTHROPIC_DEFAULT_SONNET_MODEL=deepseek-v4-pro[1m]
export ANTHROPIC_DEFAULT_HAIKU_MODEL=deepseek-v4-flash
export CLAUDE_CODE_SUBAGENT_MODEL=deepseek-v4-flash
export CLAUDE_CODE_EFFORT_LEVEL=max
DEEPSEEK
    fi
done

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
add_line 'export LANG=en_US.UTF-8' /config/.bashrc
add_line 'export LANGUAGE=en_US:en' /config/.bashrc
add_line 'export LC_ALL=en_US.UTF-8' /config/.bashrc

# ---- Fix ownership ----
chown -R "$USER:$USER" /config

echo "[cloud-dev] Init complete. SSH is running as $USER. nvm, Node, Claude Code are ready."
