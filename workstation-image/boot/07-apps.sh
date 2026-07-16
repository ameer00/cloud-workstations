#!/bin/bash
# =============================================================================
# 07-apps.sh — Update apps to latest versions on boot
# =============================================================================
# Updates Claude Code, Gemini CLI (npm), Nix apps (home-manager), and
# Antigravity. Logs to ~/logs/app-update.log.
# =============================================================================

USER="user"
HOME_DIR="/home/user"
LOG_DIR="$HOME_DIR/logs"
LOG_FILE="$LOG_DIR/app-update.log"
NIX_SH="$HOME_DIR/.nix-profile/etc/profile.d/nix.sh"
FAILURES=0

log() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] [07-apps] $1"
    echo "$msg"
    echo "$msg" >> "$LOG_FILE"
}

run_step() {
    local step_name="$1"
    shift
    "$@" >> "$LOG_FILE" 2>&1
    local rc=$?
    if [ $rc -ne 0 ]; then
        log "FAIL: $step_name exited with code $rc"
        FAILURES=$((FAILURES + 1))
    fi
    return $rc
}

get_chrome_version() {
    runuser -u $USER -- bash -c ". $NIX_SH && google-chrome-stable --version" 2>/dev/null | tr -d '\n' || echo "not found"
}

get_signal_version() {
    runuser -u $USER -- bash -c ". $NIX_SH && nix-store -qR \$(readlink -f $HOME_DIR/.nix-profile)" 2>/dev/null | grep -oP 'signal-desktop-[0-9.]+' | head -1 || echo "not found"
}

# Create log directory
runuser -u $USER -- mkdir -p "$LOG_DIR"

log "=== App update started ==="

# --- Guard: verify user account exists ---
if ! id -u "$USER" >/dev/null 2>&1; then
    log "FATAL: user '$USER' does not exist — aborting app updates (is 011_bootstrap.sh running after 010_add-user.sh?)"
    exit 1
fi

# --- Update npm global packages (Claude Code, Gemini CLI) ---
log "Updating npm global packages..."
run_step "npm-global-update" runuser -u $USER -- bash -c ". $NIX_SH && export NPM_CONFIG_PREFIX=$HOME_DIR/.npm-global && npm update -g @anthropic-ai/claude-code @google/gemini-cli @openai/codex @sourcegraph/cody @mariozechner/pi-coding-agent"
log "npm update complete"

# --- Install/update GitHub Copilot CLI extension ---
log "Updating GitHub Copilot CLI..."
run_step "gh-copilot-update" runuser -u $USER -- bash -c ". $NIX_SH && gh extension install github/gh-copilot 2>/dev/null || gh extension upgrade gh-copilot"
log "GitHub Copilot CLI update complete"

# --- Update OpenCode (Go binary) ---
log "Updating OpenCode..."
run_step "opencode-update" runuser -u $USER -- bash -c "export GOROOT=$HOME_DIR/go && export GOPATH=$HOME_DIR/gopath && export PATH=\$GOROOT/bin:\$GOPATH/bin:\$PATH && go install github.com/opencode-ai/opencode@latest"
log "OpenCode update complete"

# --- Update Nix channel + Home Manager (VSCode, IntelliJ, etc.) ---
log "Chrome version before update: $(get_chrome_version)"
log "Signal version before update: $(get_signal_version)"

log "Updating Nix channel and Home Manager..."
run_step "nix-home-manager-update" runuser -u $USER -- bash -c ". $NIX_SH && nix-channel --update && home-manager switch"
log "Nix/Home Manager update complete"

log "Chrome version after update: $(get_chrome_version)"
log "Signal version after update: $(get_signal_version)"

log "=== App update complete (failures: $FAILURES) ==="
