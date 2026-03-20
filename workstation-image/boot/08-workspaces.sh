#!/bin/bash
# =============================================================================
# 08-workspaces.sh — Auto-launch apps across 4 Sway workspaces
# =============================================================================
# Waits for Sway to be ready, then launches:
#   ws1 = foot terminal, ws2 = Chrome, ws3 = Antigravity, ws4 = foot terminal
# Idempotent: skips if windows already exist.
# =============================================================================

USER="user"
NIX="/home/user/.nix-profile/bin"
SWAYMSG="$NIX/swaymsg"
FOOT="$NIX/foot"
ANTIGRAVITY="/home/user/.antigravity/antigravity/antigravity"

# Environment for swaymsg
export WAYLAND_DISPLAY=wayland-1
export XDG_RUNTIME_DIR=/run/user/1000

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [08-workspaces] $1"; }

# Discover SWAYSOCK (swaymsg needs it to connect)
find_swaysock() {
    ls /run/user/1000/sway-ipc.*.sock 2>/dev/null | head -1
}

sway_cmd() {
    local sock
    sock="$(find_swaysock)"
    if [ -z "$sock" ]; then
        return 1
    fi
    runuser -u $USER -- env WAYLAND_DISPLAY=wayland-1 XDG_RUNTIME_DIR=/run/user/1000 SWAYSOCK="$sock" "$SWAYMSG" "$@"
}

# --- Wait for Sway ---
log "Waiting for Sway to be ready..."
for i in $(seq 1 60); do
    if sway_cmd -t get_tree >/dev/null 2>&1; then
        log "Sway is ready (attempt $i)"
        break
    fi
    if [ "$i" -eq 60 ]; then
        log "ERROR: Sway not ready after 60 seconds — aborting"
        exit 1
    fi
    sleep 2
done

# --- Idempotent check: skip if windows already exist ---
WINDOW_COUNT=$(sway_cmd -t get_tree 2>/dev/null | grep -o '"pid"' | wc -l)
if [ "${WINDOW_COUNT:-0}" -gt 1 ]; then
    log "Windows already open ($WINDOW_COUNT found) — skipping"
    exit 0
fi

# --- Launch apps on workspaces ---
launch_on_workspace() {
    local ws="$1"
    shift
    sway_cmd "workspace number $ws"
    sleep 0.5
    local sock
    sock="$(find_swaysock)"
    runuser -u $USER -- env WAYLAND_DISPLAY=wayland-1 XDG_RUNTIME_DIR=/run/user/1000 SWAYSOCK="$sock" "$@" &
    sleep 2
    log "Launched on workspace $ws: $*"
}

# Workspace 1: foot terminal
launch_on_workspace 1 "$FOOT"

# Workspace 2: Google Chrome
launch_on_workspace 2 google-chrome-stable --ozone-platform=wayland --disable-dev-shm-usage

# Workspace 3: Antigravity
if [ -x "$ANTIGRAVITY" ]; then
    launch_on_workspace 3 "$ANTIGRAVITY" --no-sandbox --ozone-platform=wayland --disable-gpu --disable-dev-shm-usage
else
    log "WARNING: Antigravity not found at $ANTIGRAVITY — skipping ws3"
fi

# Workspace 4: foot terminal
launch_on_workspace 4 "$FOOT"

# Switch back to workspace 1
sleep 1
sway_cmd "workspace number 1"
log "All workspaces launched, switched to workspace 1"
