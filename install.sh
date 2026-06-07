#!/usr/bin/env bash

# cineflix-cli automated installer script
# Safe execution: exit on error or unset variables
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;36m'
NC='\033[0m' # No Color

log_info() {
    printf "${BLUE}[➜]${NC} %s\n" "$1"
}

log_success() {
    printf "${GREEN}[✔]${NC} %s\n" "$1"
}

log_warn() {
    printf "${YELLOW}[!]${NC} %s\n" "$1"
}

log_error() {
    printf "${RED}[✖]${NC} %s\n" "$1" >&2
}

# Check helper dependencies
for cmd in curl grep sed; do
    if ! command -v "$cmd" &>/dev/null; then
        log_error "Required installer tool '$cmd' is not installed. Please install it first."
        exit 1
    fi
done

# Detect OS
OS_TYPE="$(uname -s)"
DISTRO="unknown"

if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
elif [ -d "/data/data/com.termux" ]; then
    DISTRO="termux"
elif [ "$OS_TYPE" = "Darwin" ]; then
    DISTRO="macos"
fi

log_info "Detected OS: $OS_TYPE / Distribution: $DISTRO"

# Dependencies mapping
DEPS=(fzf jq openssl ffmpeg aria2 yt-dlp git patch)

# Install missing dependencies
log_info "Checking and installing dependencies..."

case "$DISTRO" in
    ubuntu|debian|raspbian|pop)
        log_info "Updating package list..."
        sudo apt-get update -qq
        log_info "Installing dependencies via apt..."
        sudo apt-get install -y -qq fzf jq openssl ffmpeg aria2 yt-dlp git patch mpv
        ;;
    fedora)
        log_info "Installing dependencies via dnf..."
        sudo dnf install -y -q fzf jq openssl ffmpeg aria2 yt-dlp git patch mpv
        ;;
    arch|manjaro)
        log_info "Installing dependencies via pacman..."
        sudo pacman -Sy --noconfirm --needed fzf jq openssl ffmpeg aria2 yt-dlp git patch mpv
        ;;
    macos)
        if ! command -v brew &>/dev/null; then
            log_warn "Homebrew is not installed. Installing it first..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        log_info "Installing dependencies via brew..."
        brew install -q fzf jq openssl ffmpeg aria2 yt-dlp git patch
        # Suggest IINA for macOS
        if ! brew list --cask iina &>/dev/null; then
            log_info "Installing IINA player (native macOS player with MPV core)..."
            brew install --cask -q iina
        fi
        ;;
    termux)
        log_info "Installing dependencies via pkg..."
        pkg update -y -q
        pkg install -y -q fzf jq openssl-tool ffmpeg aria2 yt-dlp git patch termux-am
        log_warn "Please install VLC or MPV from the Android Play Store or F-Droid manually."
        ;;
    *)
        log_warn "Unsupported distribution '$DISTRO'. You must manually install dependencies: ${DEPS[*]} and a media player (mpv/vlc)."
        ;;
esac

# Find suitable install location
INSTALL_DIR="/usr/local/bin"
if [ "$DISTRO" = "termux" ]; then
    INSTALL_DIR="$PREFIX/bin"
elif [ ! -w "$INSTALL_DIR" ]; then
    # Fallback to user local bin if /usr/local/bin is not writable and we are not root
    INSTALL_DIR="$HOME/.local/bin"
    mkdir -p "$INSTALL_DIR"
    
    # Ensure local bin is in PATH
    if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
        SHELL_RC=""
        if [ -n "${SHELL:-}" ]; then
            SHELL_NAME=$(basename "$SHELL")
            if [ "$SHELL_NAME" = "zsh" ]; then
                SHELL_RC="$HOME/.zshrc"
            elif [ "$SHELL_NAME" = "bash" ]; then
                SHELL_RC="$HOME/.bashrc"
            fi
        fi
        
        if [ -n "$SHELL_RC" ] && [ -f "$SHELL_RC" ]; then
            log_info "Adding $INSTALL_DIR to PATH in $SHELL_RC"
            echo "export PATH=\"\$PATH:$INSTALL_DIR\"" >> "$SHELL_RC"
            log_warn "Please restart your terminal or run 'source $SHELL_RC' after installation."
        else
            log_warn "Please manually add '$INSTALL_DIR' to your system PATH environment variable."
        fi
    fi
fi

log_info "Installing cineflix-cli to $INSTALL_DIR..."

# If we are installing locally from the cloned repo, copy it.
# Otherwise, download from master branch.
if [ -f "./cineflix-cli" ]; then
    if [ -w "$INSTALL_DIR" ]; then
        cp ./cineflix-cli "$INSTALL_DIR/cineflix-cli"
    else
        sudo cp ./cineflix-cli "$INSTALL_DIR/cineflix-cli"
    fi
else
    log_info "Downloading latest script from main repository..."
    TEMP_FILE=$(mktemp)
    curl -fsSL "https://raw.githubusercontent.com/simoabid/cineflix-cli/master/cineflix-cli" -o "$TEMP_FILE"
    
    if [ -w "$INSTALL_DIR" ]; then
        mv "$TEMP_FILE" "$INSTALL_DIR/cineflix-cli"
    else
        sudo mv "$TEMP_FILE" "$INSTALL_DIR/cineflix-cli"
    fi
fi

# Make it executable
if [ -w "$INSTALL_DIR/cineflix-cli" ]; then
    chmod +x "$INSTALL_DIR/cineflix-cli"
else
    sudo chmod +x "$INSTALL_DIR/cineflix-cli"
fi

log_success "cineflix-cli has been successfully installed to $INSTALL_DIR/cineflix-cli!"
log_info "Run it using the command: cineflix-cli"
