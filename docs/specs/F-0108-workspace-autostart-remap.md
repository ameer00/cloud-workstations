# F-0108: Workspace Autostart Remap

**Type:** Enhancement + Bug Fix
**Priority:** P0 (critical)
**Status:** Approved
**Requested by:** PO
**Date:** 2026-07-17

## Problem

The workspace autostart script (`workstation-image/boot/08-workspaces.sh`) launches
apps on 4 sway workspaces at boot via the `ws-autolaunch` systemd service. The
current assignment is:

| Workspace | Current app | Status |
|-----------|------------|--------|
| ws1 | foot terminal | Working |
| ws2 | Google Chrome | **BROKEN -- Chrome window never appears** |
| ws3 | Antigravity | Working |
| ws4 | foot terminal | Working |

The PO wants the assignment changed to:

| Workspace | Desired app |
|-----------|------------|
| ws1 | foot terminal |
| ws2 | foot terminal |
| ws3 | foot terminal |
| ws4 | Google Chrome |

Antigravity autostart must be removed entirely. Chrome autostart is currently
broken (the window never appears despite the process launching), so fixing the
Chrome launch mechanism is explicitly in scope -- merely re-assigning the
workspace number is insufficient.

### Root cause context

The autostart script launches Chrome via `runuser -u user -- env WAYLAND_DISPLAY=wayland-1
XDG_RUNTIME_DIR=/run/user/1000 SWAYSOCK=<sock> google-chrome-stable --ozone-platform=wayland
--disable-dev-shm-usage`. This runs outside the sway session, constructing the
Wayland environment manually. In contrast, the **working** manual keybinding
(`Ctrl+Shift+B` in sway config, line 104) runs `google-chrome-stable --disable-dev-shm-usage`
via sway `exec`, which inherits the full sway session environment (including
`DBUS_SESSION_BUS_ADDRESS`, `XDG_SESSION_TYPE`, and any other variables set by
sway itself). The delta between these two launch methods -- particularly
`--ozone-platform=wayland` and the absence of full session environment -- is the
prime suspect for the broken autostart.

The SWE must root-cause the failure, but the most likely fix is to use
`sway_cmd exec ...` (which calls `swaymsg exec` and inherits the full session
environment) instead of `runuser` with a hand-crafted env, and to drop
`--ozone-platform=wayland` to match the working keybinding.

## Requirements

### R1: Remap workspace assignments

Modify `workstation-image/boot/08-workspaces.sh` so the autostart layout is:
- ws1 = foot terminal
- ws2 = foot terminal
- ws3 = foot terminal
- ws4 = Google Chrome

Remove the Antigravity launch block entirely (the `if [ -x "$ANTIGRAVITY" ]` block
and the `ANTIGRAVITY` variable definition).

### R2: Fix Chrome autostart so a Chrome window actually appears on ws4

Root-cause why Chrome launched via `runuser` with a hand-crafted environment
does not produce a visible window, while the sway keybinding works. Fix the
launch mechanism so Chrome reliably appears on ws4 after boot.

Key observations for the SWE:
- The working keybinding uses `sway exec` (full session env) with only
  `--disable-dev-shm-usage` (no `--ozone-platform=wayland`).
- The broken autostart uses `runuser` outside sway with `--ozone-platform=wayland`
  and a manually constructed env missing DBUS, XDG_SESSION_TYPE, etc.
- The `sway_cmd` helper function in the script already wraps `swaymsg` --
  consider using `sway_cmd exec "google-chrome-stable --disable-dev-shm-usage"`
  to match the keybinding approach.
- Alternatively, ensure the `runuser` env includes all necessary session
  variables (DBUS_SESSION_BUS_ADDRESS, etc.) and test whether
  `--ozone-platform=wayland` is needed or harmful.

### R3: Update script header comments and log messages

The header comment currently says `ws2 = Chrome, ws3 = Antigravity`. Update all
comments and log messages to reflect the new layout.

### R4: Persistence across reboots, teardown+setup, and fresh project setup

Per project persistence rules (CLAUDE.md), the change must be applied to:
1. **Repo source**: `workstation-image/boot/08-workspaces.sh` (committed)
2. **Live workstations**: `~/boot/08-workspaces.sh` on gement01, gement02, and
   gement03 (copied from repo)
3. **Setup script**: Verify `scripts/cloud-build-setup.sh` deploys the updated
   `08-workspaces.sh` correctly for fresh project setups (it should, since it
   copies boot scripts from the repo, but verify explicitly)

### R5: Update boot test coverage

Add or update tests in `workstation-image/boot/10-tests.sh`:
- Test that `08-workspaces.sh` does NOT contain `antigravity` (case-insensitive)
- Test that `08-workspaces.sh` contains the Chrome launch on workspace 4
- Test that `08-workspaces.sh` contains foot terminal launches on workspaces 1, 2, 3
- Existing Chrome-related tests (e.g., Chrome path, Chrome wrapper flags) must
  continue to pass

### R6: Update documentation

Update `docs/STARTUP_SCRIPTS.md` to reflect the new workspace layout (ws1-3
foot, ws4 Chrome, Antigravity removed).

## Acceptance Criteria

- [ ] After a full stop/start cycle, ws1, ws2, ws3 each have a foot terminal
      window and ws4 has a Google Chrome window
- [ ] Chrome window on ws4 is actually visible and functional (not just a
      process running with no window)
- [ ] Antigravity does NOT autostart (no Antigravity process launched by
      08-workspaces.sh; Antigravity itself remains installed and manually
      launchable via keybinding)
- [ ] Verified via full stop/start cycle on at least 2 of 3 projects
      (gement01, gement02, gement03)
- [ ] `~/logs/boot-test-results.txt` shows all PASS (zero regressions)
- [ ] All 5 new/updated tests in `10-tests.sh` pass
- [ ] `08-workspaces.sh` on disk at `~/boot/` matches repo version on all 3
      workstations
- [ ] `docs/STARTUP_SCRIPTS.md` updated with new workspace layout
- [ ] Change survives `home-manager switch` and `swaymsg reload` (persistence
      verified)

## Out of Scope

- Changing sway keybindings for Antigravity -- Antigravity remains manually
  launchable via its existing keybinding; only the *autostart* is removed
- Changing which apps are installed -- only the autostart assignment changes
- Fixing any pre-existing test failures unrelated to this feature
- Waybar / swaybar changes

## Dependencies

- F-0103 (Chrome /dev/shm crash fix) -- already done; Chrome wrapper includes
  `--disable-dev-shm-usage` via Nix override
- F-0029 (original auto-launch 4 workspaces) -- this feature modifies its output

## Open Questions

- None -- the PO's desired layout is unambiguous and the root-cause approach is
  well-scoped
