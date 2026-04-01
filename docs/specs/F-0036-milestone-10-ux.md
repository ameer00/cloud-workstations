# F-0036: Milestone 10 — UX Polish (Wofi, Clipboard, Snippets, Waybar)

**Type:** Enhancement
**Priority:** P1 (important)
**Status:** Approved
**Requested by:** PO
**Date:** 2026-03-31

## Problem

The Cloud Workstation desktop environment has several UX gaps that reduce daily productivity:

1. **Wofi app launcher is broken** -- Pressing the launcher keybinding (`$mod+d`) opens Wofi but only shows Antigravity. All Nix-installed apps (VSCode, IntelliJ, foot, thunar, Chrome) have `.desktop` files in `/home/user/.nix-profile/share/applications/` but Wofi cannot find them because `XDG_DATA_DIRS` is empty in sway's environment. System apps in `/usr/share/applications/` are also missing. Additionally, there is no Wofi configuration or styling -- `~/.config/wofi/` does not exist.

2. **CTRL+SHIFT+A clipboard history picker does not work** -- The sway config binds `$mod+a` to `clipman pick --tool wofi`, and autostart includes `wl-paste -t text --watch clipman store` to capture clipboard history. However, the `wl-paste` clipman daemon is NOT running (confirmed via `pgrep`). Both binaries exist at `/home/user/.nix-profile/bin/` but the daemon likely fails to start due to the same nvidia `LD_LIBRARY_PATH` conflict that affects other Nix binaries.

3. **CTRL+SHIFT+S snippet picker does not exist** -- The sway config binds a key to a snippet picker script at `/home/user/.local/bin/snippet-picker`, but this script was never created. The PO wants a configurable Wofi-based snippet picker with a user-editable snippet config file.

4. **Status bar is basic swaybar** -- The workstation uses swaybar with a custom `sway-status` script (i3bar JSON protocol). Waybar is already installed via Nix (`/home/user/.nix-profile/bin/waybar`) and the repo already contains a full waybar config with Tokyo Night theme (`workstation-image/configs/waybar/config.jsonc` and `style.css`). The PO wants to switch to waybar and add an "Apps" dropdown button at the far left for quick access to commonly used applications.

## Requirements

### Feature 1: Wofi App Launcher Fix + Categories + Styling

1. The Wofi launch command in the sway config MUST set `XDG_DATA_DIRS` to include both `/home/user/.nix-profile/share` and `/usr/share` so Wofi discovers all `.desktop` files
2. Wofi MUST also clear `LD_LIBRARY_PATH` using `env -u LD_LIBRARY_PATH` to prevent nvidia library conflicts with Nix binaries
3. A Wofi config file MUST be created at `~/.config/wofi/config` with sensible defaults:
   - `show=drun` (desktop application launcher mode)
   - `width=600`, `height=400` (or similar comfortable dimensions)
   - `allow_images=true` (show app icons)
   - `insensitive=true` (case-insensitive search)
   - `prompt=Apps` (search prompt text)
   - `columns=1` (single column list)
4. A Wofi style sheet MUST be created at `~/.config/wofi/style.css` using the Tokyo Night color palette:
   - Background: `#1a1b26`, foreground/text: `#c0caf5`
   - Selected/focused item: accent `#7aa2f7` background
   - Input/search bar: surface `#24283b` background
   - Scrollbar, borders: muted `#414868`
   - Rounded corners, clean modern look consistent with waybar styling
5. The boot script MUST deploy the wofi config and style files to `~/.config/wofi/` on each boot
6. Wofi MUST display all installed applications including: Antigravity, VSCode, IntelliJ IDEA, Google Chrome, foot terminal, Thunar file manager, and any other apps with `.desktop` files

### Feature 2: Fix CTRL+SHIFT+A (Clipboard History Picker)

1. The `wl-paste` + `clipman store` autostart command in the sway config MUST be wrapped with `env -u LD_LIBRARY_PATH` to prevent nvidia library conflicts that prevent the daemon from starting
2. Full Nix binary paths MUST be used for both `wl-paste` and `clipman` in the autostart exec: `/home/user/.nix-profile/bin/wl-paste` and `/home/user/.nix-profile/bin/clipman`
3. The `clipman pick` keybinding command MUST also use `env -u LD_LIBRARY_PATH` and set `XDG_DATA_DIRS` (so the wofi invocation within clipman works correctly)
4. After the fix, pressing CTRL+SHIFT+A MUST open a Wofi-styled clipboard history picker showing previously copied text entries
5. Selecting an entry MUST paste it to the clipboard

### Feature 3: Fix CTRL+SHIFT+S (Snippet Picker)

1. A snippet picker script MUST be created at `/home/user/.local/bin/snippet-picker`
2. Snippets MUST be stored in a user-editable config file at `~/.config/snippets/snippets.conf`
3. The snippet config format MUST be simple and human-editable -- one snippet per line with a label and value separated by a delimiter (e.g., `label | value` or similar)
4. The script MUST read the config file, present snippet labels in Wofi, and copy the selected snippet's value to the clipboard via `wl-copy`
5. The script MUST use `env -u LD_LIBRARY_PATH` for Wofi and `wl-copy` invocations to avoid nvidia library conflicts
6. The script MUST be executable (`chmod +x`)
7. A default set of starter snippets MUST be included (e.g., email address, common commands, code patterns) that the user can customize
8. The boot script MUST deploy the snippet picker script and default snippet config on each boot (creating `~/.config/snippets/` if needed, but NOT overwriting an existing `snippets.conf` to preserve user customizations)

### Feature 4: Switch to Waybar + Apps Dropdown

1. The sway config MUST replace the `bar { ... }` block (swaybar) with `exec waybar` (or exec with full Nix path and `env -u LD_LIBRARY_PATH`)
2. The existing waybar config (`workstation-image/configs/waybar/config.jsonc`) MUST be deployed to `~/.config/waybar/config.jsonc`
3. The existing waybar style (`workstation-image/configs/waybar/style.css`) MUST be deployed to `~/.config/waybar/style.css`
4. A `custom/apps` module MUST be added to the waybar config at the far-left position (`modules-left`) with:
   - A recognizable icon/label (e.g., a grid/menu icon or "Apps" text)
   - On click: launch a Wofi menu showing the main applications: Antigravity, VSCode, IntelliJ IDEA, Google Chrome, Terminal (foot), File Manager (Thunar)
   - The apps menu script MUST handle launching the selected app (using the correct exec commands with `env -u LD_LIBRARY_PATH` where needed)
5. The boot script MUST deploy waybar config files to `~/.config/waybar/` on each boot
6. Waybar MUST use the existing Tokyo Night styled config and CSS already in the repo
7. The old swaybar `bar { ... }` block and `sway-status` script references MUST be removed or commented out from the sway config

## Files to Change

| File | Change |
|------|--------|
| `workstation-image/configs/sway/config` | Fix Wofi exec (add `XDG_DATA_DIRS`, `env -u LD_LIBRARY_PATH`); fix clipman autostart (wrap with `env -u LD_LIBRARY_PATH`); fix clipman pick keybinding; replace swaybar `bar {}` block with waybar exec |
| `workstation-image/configs/wofi/config` | **New file** -- Wofi configuration (drun mode, dimensions, options) |
| `workstation-image/configs/wofi/style.css` | **New file** -- Wofi Tokyo Night theme stylesheet |
| `workstation-image/configs/waybar/config.jsonc` | Add `custom/apps` module to `modules-left`; add apps module definition with on-click script |
| `workstation-image/configs/waybar/style.css` | Add styling for `custom/apps` module (if not already present) |
| `workstation-image/configs/snippets/snippets.conf` | **New file** -- Default snippet definitions |
| `workstation-image/scripts/snippet-picker` | **New file** -- Snippet picker shell script for Wofi + wl-copy |
| `workstation-image/scripts/apps-menu` | **New file** -- Apps dropdown menu script for waybar (Wofi-based) |
| `boot/NN-wofi.sh` | **New file** -- Boot script to deploy wofi config to `~/.config/wofi/` |
| `boot/NN-snippets.sh` | **New file** -- Boot script to deploy snippet picker + config (no-clobber on existing snippets.conf) |
| `boot/NN-waybar.sh` | **New or updated file** -- Boot script to deploy waybar config to `~/.config/waybar/` |

## Acceptance Criteria

### Feature 1: Wofi App Launcher
- [ ] Pressing the app launcher keybinding opens Wofi and shows ALL installed applications (Nix apps + system apps)
- [ ] Wofi displays Antigravity, VSCode, IntelliJ IDEA, Google Chrome, foot, Thunar, and other installed apps
- [ ] Wofi has Tokyo Night themed styling (dark background `#1a1b26`, accent `#7aa2f7`, text `#c0caf5`)
- [ ] Wofi config exists at `~/.config/wofi/config` with drun mode and sensible defaults
- [ ] Wofi style exists at `~/.config/wofi/style.css`
- [ ] Selecting an app from Wofi launches it successfully
- [ ] Case-insensitive search works in Wofi

### Feature 2: Clipboard History Picker
- [ ] The `wl-paste` + `clipman store` daemon is running after boot (verify with `pgrep`)
- [ ] Pressing CTRL+SHIFT+A opens a Wofi-styled clipboard history picker
- [ ] Previously copied text entries appear in the picker
- [ ] Selecting an entry copies it back to the clipboard
- [ ] The daemon survives across the session (does not crash due to library conflicts)

### Feature 3: Snippet Picker
- [ ] Pressing CTRL+SHIFT+S opens a Wofi-styled snippet picker
- [ ] Default snippets are displayed with readable labels
- [ ] Selecting a snippet copies the snippet value to the clipboard
- [ ] Snippet config file exists at `~/.config/snippets/snippets.conf` and is human-editable
- [ ] The user can add/remove/edit snippets in the config file and changes are reflected on next invocation
- [ ] Boot script does NOT overwrite an existing `snippets.conf` (preserves user customizations)
- [ ] The snippet picker script is executable and located at `~/.local/bin/snippet-picker`

### Feature 4: Waybar + Apps Dropdown
- [ ] Waybar is running instead of swaybar after boot
- [ ] Waybar displays all existing modules: workspaces, CPU, memory, disk, GPU, network, clock
- [ ] Waybar uses Tokyo Night theme consistent with the rest of the desktop
- [ ] An "Apps" button/icon appears at the far left of waybar
- [ ] Clicking the Apps button opens a Wofi menu with main applications listed
- [ ] Selecting an app from the Apps dropdown launches it successfully
- [ ] The old swaybar block is removed from the sway config
- [ ] Waybar config is deployed from repo to `~/.config/waybar/` on boot

### Cross-cutting
- [ ] All Wofi invocations use `env -u LD_LIBRARY_PATH` to avoid nvidia conflicts
- [ ] All Wofi invocations set `XDG_DATA_DIRS` to include Nix and system app directories
- [ ] Boot scripts deploy all config files correctly on workstation start
- [ ] No regressions to existing sway keybindings or desktop functionality

## Out of Scope

- Global fix for the nvidia `LD_LIBRARY_PATH` conflict (per-invocation workaround is acceptable)
- Wofi plugin development or custom modes beyond `drun` and `dmenu`
- Waybar custom modules beyond the Apps dropdown (existing modules are sufficient)
- Multi-monitor waybar configuration
- Animated transitions or advanced Wofi theming beyond Tokyo Night palette

## Dependencies

- F-0017 (Nix Home Manager Apps -- provides `.desktop` files and Nix binaries)
- F-0016 / F-0020 (Sway + Waybar -- established sway config and waybar configs in repo)
- F-0035 (Fix IDE Keybindings -- established the `env -u LD_LIBRARY_PATH` pattern for Nix binaries)

## Open Questions

- None -- all four issues are fully diagnosed and solutions are well-defined based on investigation findings
