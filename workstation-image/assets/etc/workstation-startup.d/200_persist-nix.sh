#!/bin/bash
# Restore /nix symlink from persistent disk on boot
# Nix store lives on persistent HOME disk at /home/user/nix
# Container root resets on restart, so we re-create the symlink each boot

if [ -d /home/user/nix ] && [ ! -L /nix ]; then
    rm -rf /nix 2>/dev/null
    ln -s /home/user/nix /nix
    echo "Restored /nix symlink to /home/user/nix"
fi

# Restore nvidia PATH/LD_LIBRARY_PATH for GPU access
if [ -d /var/lib/nvidia/bin ]; then
    cat > /etc/profile.d/nvidia.sh << 'EOF'
export PATH=/var/lib/nvidia/bin:$PATH
export LD_LIBRARY_PATH=/var/lib/nvidia/lib64:$LD_LIBRARY_PATH
EOF
    echo "Restored nvidia profile script"
fi
