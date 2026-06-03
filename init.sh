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
    zsh

# ---- SSH server ----
echo "[cloud-dev] Configuring SSH..."
sed -i 's/#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
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

# ---- npm global prefix → /config ----
if [ -d /config/.nvm ]; then
    su - "$USER" -c 'mkdir -p ~/.npm-global'
    if [ ! -f /config/.npmrc ] || ! grep -q "prefix" /config/.npmrc 2>/dev/null; then
        echo 'prefix=~/.npm-global' >> /config/.npmrc
    fi
fi

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
    add_line 'export PATH=~/go/bin:~/.npm-global/bin:$PATH' "$rcfile"
    add_line 'export NVM_DIR="$HOME/.nvm"' "$rcfile"
    add_line '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' "$rcfile"
done

# ---- DeepSeek API env vars (for Claude Code) ----
if ! grep -q "ANTHROPIC_BASE_URL" /config/.zshrc 2>/dev/null; then
    cat >> /config/.zshrc << 'DEEPSEEK'
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

# ---- Force English locale ----
add_line 'export LANG=en_US.UTF-8' /config/.bashrc
add_line 'export LANGUAGE=en_US:en' /config/.bashrc
add_line 'export LC_ALL=en_US.UTF-8' /config/.bashrc

# ---- Fix ownership ----
chown -R "$USER:$USER" /config

echo "[cloud-dev] Init complete. SSH is running as $USER. nvm, Node, Claude Code are ready."
