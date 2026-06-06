#!/bin/bash
# ================================================================
# Cloud Dev Stack — Interactive Installer
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/Piero24/Cloud-Dev-Desktop/main/install.sh | bash
# ================================================================
set -e

GITHUB_RAW="https://raw.githubusercontent.com/Piero24/Cloud-Dev-Desktop/main"
DEFAULT_PATH="/DATA/AppData/cloud-dev"

echo ""
echo "  ╔════════════════════════════════════════════════╗"
echo "  ║         Cloud Dev Stack — Installer            ║"
echo "  ╚════════════════════════════════════════════════╝"
echo ""

# ---- Ask for base path with confirmation loop ----
while true; do
    echo "Where should Cloud Dev Stack store its data?"
    echo "(Projects, configs, and VS Code settings will live here)"
    echo ""
    read -p "Base path [$DEFAULT_PATH]: " BASE_PATH < /dev/tty
    BASE_PATH="${BASE_PATH:-$DEFAULT_PATH}"

    echo ""
    read -p "Confirm path '$BASE_PATH'? [y/N]: " CONFIRM < /dev/tty
    case "$CONFIRM" in
        [yY]|[yY][eE][sS])
            break
            ;;
        [nN]|[nN][oO]|"")
            echo ""
            echo "Let's try a different path..."
            echo ""
            ;;
        *)
            echo ""
            echo "Please answer y (yes) or n (no)."
            echo ""
            ;;
    esac
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Base path: $BASE_PATH"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ---- Create directories ----
echo "[1/3] Creating directories..."
mkdir -p "$BASE_PATH"/{projects,init.d,shared}
echo "      ✓ $BASE_PATH/config"
echo "      ✓ $BASE_PATH/projects"
echo "      ✓ $BASE_PATH/init.d"
echo "      ✓ $BASE_PATH/shared"

# ---- Download init scripts ----
echo ""
echo "[2/3] Downloading container init scripts..."
curl -fsSL "$GITHUB_RAW/init.sh" -o "$BASE_PATH/init.d/99-ssh.sh"
chmod +x "$BASE_PATH/init.d/99-ssh.sh"
echo "      ✓ init.sh → $BASE_PATH/init.d/99-ssh.sh"

curl -fsSL "$GITHUB_RAW/init.d/99-vscode-env.sh" -o "$BASE_PATH/init.d/99-vscode-env.sh"
chmod +x "$BASE_PATH/init.d/99-vscode-env.sh"
echo "      ✓ 99-vscode-env.sh → $BASE_PATH/init.d/99-vscode-env.sh"

# ---- Download compose-casaos.yaml ----
echo ""
echo "[3/3] Downloading CasaOS Compose file..."
curl -fsSL "$GITHUB_RAW/compose-casaos.yaml" -o "$BASE_PATH/compose-casaos.yaml"
echo "      ✓ compose-casaos.yaml → $BASE_PATH/compose-casaos.yaml"

# ---- Done ----
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Installation complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Next steps:"
echo ""
echo "  1. Edit the values in the compose file:"
echo "     nano $BASE_PATH/compose-casaos.yaml"
echo ""
echo "     Replace (all under the desktop service):"
echo "       CHANGE_ME_USERNAME       → your system username"
echo "       CHANGE_ME_WEB_PASSWORD   → your login password"
echo "       CHANGE_ME_SUDO_PASSWORD  → your sudo/SSH password"
echo "       CHANGE_ME_ANTHROPIC_KEY  → your Anthropic API key"
echo "       CHANGE_ME_GIT_NAME       → your Git name"
echo "       CHANGE_ME_GIT_EMAIL      → your Git email"
echo "       CHANGE_ME_GITHUB_TOKEN   → your GitHub fine-grained PAT"
echo ""
echo "  2. Import into CasaOS:"
echo "     App Store → Custom Install → Import"
echo "     Paste the content of $BASE_PATH/compose-casaos.yaml"
echo ""
echo "  3. Expose the services through your reverse proxy of choice"
echo ""
