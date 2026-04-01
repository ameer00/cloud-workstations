# F-0035: Fix IDE Keybindings (IntelliJ + VSCode)

**Type:** Bug
**Priority:** P0 (critical)
**Status:** Approved
**Requested by:** PO
**Date:** 2026-03-31

## Problem

The IDE keybindings in the Sway window manager are broken, preventing users from launching IntelliJ IDEA (CTRL+SHIFT+M) and VSCode (CTRL+SHIFT+Y). Three distinct bugs cause these failures:

1. **IntelliJ binary name mismatch** -- The sway config references `$nix/idea-community` but the actual Nix Home Manager binary is `idea-oss` at `/home/user/.nix-profile/bin/idea-oss`. Sway log confirms: `sh: 1: /home/user/.nix-profile/bin/idea-community: not found`.

2. **IntelliJ Xwayland failure** -- Sway's built-in Xwayland uses the Nix-packaged Xwayland binary. The `sway-desktop.service` sets `LD_LIBRARY_PATH=/var/lib/nvidia/lib64` for GPU support. This nvidia LD_LIBRARY_PATH causes the Nix Xwayland to fail because nvidia's `libGL.so.1` is loaded instead of Nix's, and its transitive dependency `libX11.so.6` cannot be resolved by the Nix linker. Error: `Xwayland: error while loading shared libraries: libX11.so.6: cannot open shared object file`.

3. **VSCode GL library conflict** -- The same nvidia `LD_LIBRARY_PATH` causes Nix's `libGLESv2.so.2` to be overridden by nvidia's version, resulting in: `symbol lookup error: libGLESv2.so.2: undefined symbol: _glapi_tls_Current`. VSCode crashes silently.

### Root Cause Analysis

All three bugs share a common root cause: the nvidia `LD_LIBRARY_PATH=/var/lib/nvidia/lib64` set by `sway-desktop.service` (in `workstation-image/boot/03-sway.sh` line 27) conflicts with Nix-packaged binaries that have their own library resolution paths via the Nix linker. When nvidia libraries are injected into the library search path, they shadow Nix-provided libraries, breaking symbol resolution for Nix-built applications.

Bug 1 is a separate, simpler issue: the binary name in the sway config does not match the actual Nix package output name.

## Requirements

1. The sway config MUST use the correct IntelliJ binary name `idea-oss` instead of `idea-community`
2. Sway's built-in Xwayland MUST be disabled with the `xwayland disable` directive to prevent it from using the Nix Xwayland binary (which fails under nvidia LD_LIBRARY_PATH)
3. The system Xwayland (`/usr/bin/Xwayland :0`) MUST be launched explicitly in the sway config autostart section (note: this is already present at line 215)
4. The IntelliJ exec command MUST set `DISPLAY=:0` so IntelliJ connects to the system Xwayland instance instead of the disabled built-in one
5. The VSCode exec command MUST clear `LD_LIBRARY_PATH` using `env -u LD_LIBRARY_PATH` to prevent nvidia library conflicts
6. VSCode MUST retain its existing flags: `--no-sandbox --ozone-platform=wayland --disable-gpu --disable-dev-shm-usage`

## Files to Change

| File | Change |
|------|--------|
| `workstation-image/configs/sway/config` | Fix IntelliJ binary name (`idea-community` -> `idea-oss`), add `xwayland disable`, add `DISPLAY=:0` to IntelliJ exec, wrap VSCode exec with `env -u LD_LIBRARY_PATH` |
| `boot/08-workspaces.sh` | Check for any `idea-community` references and update to `idea-oss` (if present) |

## Acceptance Criteria

- [ ] Sway config uses `idea-oss` binary name for IntelliJ keybinding (CTRL+SHIFT+M)
- [ ] Sway config includes `xwayland disable` directive to prevent built-in Xwayland from starting
- [ ] System Xwayland (`/usr/bin/Xwayland :0`) is launched in sway autostart (already present, verify retained)
- [ ] IntelliJ exec command includes `DISPLAY=:0` environment variable
- [ ] VSCode exec command is wrapped with `env -u LD_LIBRARY_PATH` to clear nvidia library path
- [ ] VSCode retains all existing Electron flags (`--no-sandbox`, `--ozone-platform=wayland`, `--disable-gpu`, `--disable-dev-shm-usage`)
- [ ] CTRL+SHIFT+M launches IntelliJ IDEA without "not found" errors
- [ ] CTRL+SHIFT+Y launches VSCode without GL symbol lookup errors
- [ ] No references to `idea-community` remain in the codebase
- [ ] No other sway keybindings are broken by the changes

## Out of Scope

- Resolving the nvidia LD_LIBRARY_PATH conflict globally (that would require changes to the sway-desktop.service and GPU driver setup)
- Migrating other X11 apps away from the built-in Xwayland
- Adding new IDE keybindings or changing existing key assignments

## Dependencies

- F-0017 (Nix Home Manager Apps -- established the `idea-oss` binary via Home Manager)
- F-0016 (Sway + Waybar -- established the sway keybinding scheme)

## Open Questions

- None -- root causes are fully diagnosed and fixes are straightforward
