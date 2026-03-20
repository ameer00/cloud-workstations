#!/bin/bash
# =============================================================================
# 03-sway.sh — Sway desktop + wayvnc systemd services
# =============================================================================
# Creates sway-desktop and wayvnc services on the ephemeral root disk.
# Disables TigerVNC to free port 5901 for wayvnc.
# noVNC stays enabled (proxies port 80 -> localhost:5901).
# =============================================================================

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [03-sway] $1"; }

# --- Create sway-desktop.service ---
cat > /etc/systemd/system/sway-desktop.service << 'EOF'
[Unit]
Description=Sway desktop (headless for wayvnc)
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=user
PAMName=login
Environment=WLR_BACKENDS=headless
Environment=WLR_LIBINPUT_NO_DEVICES=1
Environment=XDG_RUNTIME_DIR=/run/user/1000
Environment=XDG_SESSION_TYPE=wayland
Environment=LD_LIBRARY_PATH=/var/lib/nvidia/lib64
ExecStartPre=/bin/mkdir -p /run/user/1000
ExecStartPre=/bin/chown user:user /run/user/1000
ExecStartPre=/bin/chmod 700 /run/user/1000
ExecStart=/home/user/.nix-profile/bin/sway
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
log "Created sway-desktop.service"

# --- Create wayvnc.service ---
cat > /etc/systemd/system/wayvnc.service << 'EOF'
[Unit]
Description=wayvnc VNC server for Sway
After=sway-desktop.service
Requires=sway-desktop.service

[Service]
Type=simple
User=user
Environment=XDG_RUNTIME_DIR=/run/user/1000
Environment=WAYLAND_DISPLAY=wayland-1
ExecStartPre=/bin/sleep 3
ExecStart=/home/user/.nix-profile/bin/wayvnc --output=HEADLESS-1 0.0.0.0 5901
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
log "Created wayvnc.service"

# --- Enable services ---
ln -sf /etc/systemd/system/sway-desktop.service /etc/systemd/system/multi-user.target.wants/
ln -sf /etc/systemd/system/wayvnc.service /etc/systemd/system/multi-user.target.wants/
log "Enabled sway-desktop and wayvnc services"

# --- Disable and mask TigerVNC ---
rm -f /etc/systemd/system/multi-user.target.wants/tigervnc.service
ln -sf /dev/null /etc/systemd/system/tigervnc.service
pkill -f Xtigervnc 2>/dev/null || true
log "Disabled and masked TigerVNC (port 5901 now served by wayvnc)"
