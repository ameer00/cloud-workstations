#!/bin/bash
# =============================================================================
# 011_bootstrap.sh — Bridge to persistent disk bootstrap
# =============================================================================
# This is the ONLY custom startup script in the Docker image.
# It delegates all setup to ~/boot/setup.sh on the persistent disk.
# =============================================================================

SETUP="/home/user/boot/setup.sh"

if [ -f "$SETUP" ]; then
    echo "[011_bootstrap] Running persistent disk bootstrap: $SETUP"
    bash "$SETUP" 2>&1
else
    echo "[011_bootstrap] WARNING: $SETUP not found — persistent disk may not be mounted yet"
fi
