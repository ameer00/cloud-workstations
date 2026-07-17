#!/bin/bash
# =============================================================================
# 08-workspaces.sh — Auto-launch apps across 4 Sway workspaces
# =============================================================================
# Waits for Sway to be ready, then launches:
#   ws1 = foot terminal, ws2 = foot terminal, ws3 = foot terminal, ws4 = Chrome
# Idempotent: skips if windows already exist.
# Runs as systemd service (ws-autolaunch) after wayvnc.service.
# =============================================================================

USER="user"
NIX="/home/user/.nix-profile/bin"
SWAYMSG="$NIX/swaymsg"
FOOT="$NIX/foot"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [08-workspaces] $1"; }

find_swaysock() {
    ls /run/user/1000/sway-ipc.*.sock 2>/dev/null | head -1
}

sway_cmd() {
    local sock
    sock="$(find_swaysock)"
    [ -z "$sock" ] && return 1
    runuser -u $USER -- env WAYLAND_DISPLAY=wayland-1 XDG_RUNTIME_DIR=/run/user/1000 SWAYSOCK="$sock" "$SWAYMSG" "$@"
}

# Count windows on a specific workspace
count_windows_on_ws() {
    local ws="$1"
    sway_cmd -t get_tree 2>/dev/null | python3 -c "
import json, sys
tree = json.load(sys.stdin)
def count(node, target_ws, in_ws=False):
    c = 0
    if node.get('type') == 'workspace' and node.get('num') == target_ws:
        in_ws = True
    if in_ws and node.get('pid') and node.get('pid') > 0:
        c = 1
    for child in node.get('nodes', []) + node.get('floating_nodes', []):
        c += count(child, target_ws, in_ws)
    return c
print(count(tree, $ws))
" 2>/dev/null || echo "0"
}

# --- Wait for Sway ---
log "Waiting for Sway to be ready..."
for i in $(seq 1 60); do
    if sway_cmd -t get_tree >/dev/null 2>&1; then
        log "Sway is ready (attempt $i)"
        break
    fi
    [ "$i" -eq 60 ] && { log "ERROR: Sway not ready after 60s — aborting"; exit 1; }
    sleep 2
done

# --- Idempotent check ---
WINDOW_COUNT=$(sway_cmd -t get_tree 2>/dev/null | grep -o '"pid"' | wc -l)
if [ "${WINDOW_COUNT:-0}" -gt 1 ]; then
    log "Windows already open ($WINDOW_COUNT found) — skipping"
    exit 0
fi

# --- Start Xwayland for X11 apps (IntelliJ) ---
if ! pgrep -f "Xwayland :0" >/dev/null 2>&1; then
    log "Starting Xwayland on :0..."
    sway_cmd exec "/usr/bin/Xwayland :0" 2>/dev/null
    sleep 2
    if pgrep -f "Xwayland :0" >/dev/null 2>&1; then
        log "Xwayland started on :0"
    else
        log "WARNING: Xwayland failed to start"
    fi
else
    log "Xwayland already running on :0"
fi

# --- Launch app via runuser and wait for its window to appear ---
launch_and_wait() {
    local ws="$1"
    local timeout="$2"
    shift 2

    # Switch to target workspace
    sway_cmd "workspace number $ws"
    sleep 0.5

    # Count windows before launch
    local before
    before=$(count_windows_on_ws "$ws")

    # Launch the app
    local sock
    sock="$(find_swaysock)"
    runuser -u $USER -- env WAYLAND_DISPLAY=wayland-1 XDG_RUNTIME_DIR=/run/user/1000 SWAYSOCK="$sock" "$@" &
    local app_pid=$!

    # Wait for a new window to appear on this workspace
    local elapsed=0
    while [ "$elapsed" -lt "$timeout" ]; do
        sleep 1
        elapsed=$((elapsed + 1))
        local after
        after=$(count_windows_on_ws "$ws")
        if [ "$after" -gt "$before" ]; then
            log "Launched on ws$ws (${elapsed}s): $*"
            return 0
        fi
    done
    log "WARNING: Timeout (${timeout}s) waiting for window on ws$ws: $*"
}

# --- Launch app via sway exec and wait for its window to appear ---
# Uses swaymsg exec to run the command inside sway's process tree, inheriting
# the full session environment (DBUS, XDG_SESSION_TYPE, Nix PATH, etc.).
# Required for Chrome because:
#   1. google-chrome-stable lives at ~/.nix-profile/bin/ which is NOT on the
#      minimal PATH available via runuser (only /usr/bin etc.)
#   2. The Nix Chrome wrapper needs the full session env for Wayland support
#      (NIXOS_OZONE_WL, DBUS_SESSION_BUS_ADDRESS, etc.)
#   3. --ozone-platform=wayland is unnecessary and conflicts with the Nix
#      wrapper's own NIXOS_OZONE_WL detection
sway_exec_and_wait() {
    local ws="$1"
    local timeout="$2"
    shift 2
    local cmd="$*"

    # Switch to target workspace
    sway_cmd "workspace number $ws"
    sleep 0.5

    # Count windows before launch
    local before
    before=$(count_windows_on_ws "$ws")

    # Launch via sway exec (inherits full sway session environment)
    sway_cmd exec "$cmd"

    # Wait for a new window to appear on this workspace
    local elapsed=0
    while [ "$elapsed" -lt "$timeout" ]; do
        sleep 1
        elapsed=$((elapsed + 1))
        local after
        after=$(count_windows_on_ws "$ws")
        if [ "$after" -gt "$before" ]; then
            log "Launched on ws$ws (${elapsed}s) via sway exec: $cmd"
            return 0
        fi
    done
    log "WARNING: Timeout (${timeout}s) waiting for window on ws$ws: $cmd"
}

# Workspace 1: foot terminal (fast — 5s timeout)
launch_and_wait 1 5 "$FOOT"

# Workspace 2: foot terminal (fast — 5s timeout)
launch_and_wait 2 5 "$FOOT"

# Workspace 3: foot terminal (fast — 5s timeout)
launch_and_wait 3 5 "$FOOT"

# Workspace 4: Google Chrome (via sway exec — 15s timeout)
# Uses sway exec instead of runuser to match the working Mod+B keybinding.
# --disable-dev-shm-usage is needed because /dev/shm is only 64MB in this
# container (see sway config line 106).
sway_exec_and_wait 4 15 "google-chrome-stable --disable-dev-shm-usage"

# Switch back to workspace 1
sleep 1
sway_cmd "workspace number 1"
log "All workspaces launched, switched to workspace 1"
