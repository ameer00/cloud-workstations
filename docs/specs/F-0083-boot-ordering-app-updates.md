# F-0083: Fix Boot Script Ordering & Restore App Updates

**Type:** Bug
**Priority:** P0 (critical)
**Status:** Approved
**Requested by:** PO
**Date:** 2026-07-16

## Problem

Boot-time app updates have silently failed on **every boot since 2026-03-20** (~4 months). Chrome is stuck at 146.0.7680.164 and Signal at 8.4.1 — both severely out of date.

### Root Cause

Cloud Workstations startup scripts in `/etc/workstation-startup.d/` run in lexical order as root. Our custom `000_bootstrap.sh` runs **before** Google's base-image script `010_add-user.sh`, which creates the `user` account. Every `runuser -u user` call in the boot scripts (including `07-apps.sh`) fails with:

```
runuser: user user does not exist or the user entry does not contain all the required fields
```

This was introduced in Milestone 4 (F-0033, "Persistent bootstrap") when `000_bootstrap.sh` was added to the Docker image. Evidence:

- `~/logs/app-update.log` contains 164 such failures
- Last successful update boot: 2026-03-20 20:01
- First failing boot: 2026-03-20 20:42 (the commit that introduced `000_bootstrap.sh`)

### Consequences

The following updates have been silently failing on every boot:

| Update mechanism | What it updates | Stuck version |
|---|---|---|
| `nix-channel --update && home-manager switch` | Chrome, Signal, VS Code, Cursor, Windsurf, Zed, Telegram, Slack, and all nixpkgs packages | Chrome 146.0.7680.164, Signal 8.4.1 |
| `npm update -g` | Gemini CLI, Codex, Cody, Pi | Unknown stale versions |
| `gh extension upgrade` | GitHub Copilot CLI | Unknown stale version |
| `go install ... @latest` | OpenCode | Unknown stale version |

Claude Code stayed current only because it has its own built-in auto-updater that doesn't rely on the boot scripts.

### Secondary Issue: Duplicate Chrome in Dockerfile

The Dockerfile (lines ~67-77) installs Google Chrome via apt and creates a dpkg-divert wrapper adding `--no-sandbox --no-zygote --disable-gpu --disable-dev-shm-usage`. The PO's canonical Chrome is the Nix/Home-Manager `google-chrome` package (on the persistent disk via `/nix` bind mount), which currently shadows the apt one in PATH. The apt Chrome is dead weight — it bloats the image and creates confusion about which Chrome is active.

### Tertiary Issue: No error checking in 07-apps.sh

`07-apps.sh` logs "complete" after each step regardless of whether `runuser` succeeded or failed. There is no exit-code checking, no before/after version capture, and no way to detect from logs alone that updates silently failed for months.

## Requirements

### R1: Rename bootstrap script (image asset)

Rename `workstation-image/assets/etc/workstation-startup.d/000_bootstrap.sh` to `011_bootstrap.sh` so it runs immediately **after** Google's `010_add-user.sh` creates the `user` account. The script contents do not change — only the filename.

### R2: Remove apt Chrome from Dockerfile

Remove the following from `workstation-image/Dockerfile`:
- The "Install Google Chrome" `RUN` block (apt key, repo, `apt-get install -y google-chrome-stable`) — lines ~67-70
- The `dpkg-divert` wrapper block (divert, wrapper script, chmod) — lines ~73-77

Nix Chrome (`google-chrome` in `home.nix`) is the only Chrome. The apt Chrome repo list and signing key are also removed so apt won't try to update a package that no longer exists.

### R3: Harden 07-apps.sh with error checking and version logging

Add to `07-apps.sh`:
1. **Before/after version capture** for Chrome and Signal:
   - Before updates: log the current version of `google-chrome-stable --version` and `signal-desktop --version`
   - After updates: log the new version of each
2. **Exit-code checking** on every `runuser` call:
   - Check `$?` after each `runuser` command
   - Log `FAIL: <step> exited with code N` on non-zero exit
   - Track a `FAILURES` counter; log a summary at the end
3. **User existence guard** at the top of the script:
   - Before any `runuser` call, verify `id -u user` succeeds
   - If it fails, log an explicit error and exit early rather than silently failing every step

### R4: Add boot tests to 10-tests.sh

Add the following tests to `workstation-image/boot/10-tests.sh`:

1. **Bootstrap ordering**: Verify `011_bootstrap.sh` exists in `/etc/workstation-startup.d/` and `000_bootstrap.sh` does NOT exist
2. **No apt Chrome**: Verify `dpkg -l google-chrome-stable 2>/dev/null` shows the package is NOT installed (or returns non-zero)
3. **Nix Chrome is primary**: Verify `which google-chrome-stable` resolves to a path under `~/.nix-profile/` (not `/usr/bin/`)
4. **App update success**: Verify `~/logs/app-update.log` does NOT contain "user user does not exist" in the last boot's log entries
5. **Home Manager ran**: Verify `~/logs/app-update.log` contains "Nix/Home Manager update complete" without a preceding FAIL marker

### R5: Update docs/STARTUP_SCRIPTS.md

Update the execution flow diagram and the `000_bootstrap.sh` reference to reflect the rename to `011_bootstrap.sh`. Update the description to note that it runs **after** `010_add-user.sh` (user account creation).

## Acceptance Criteria

- [ ] `011_bootstrap.sh` exists in `workstation-image/assets/etc/workstation-startup.d/`; `000_bootstrap.sh` does NOT exist
- [ ] Dockerfile does NOT contain `google-chrome-stable` apt install or `dpkg-divert` wrapper
- [ ] After image rebuild + stop/start on gement02: zero `runuser: user user does not exist` errors in `~/logs/app-update.log`
- [ ] After image rebuild + stop/start on gement02: `home-manager switch` completed successfully (visible in `~/logs/app-update.log`)
- [ ] After image rebuild + stop/start on gement02: Chrome version > 146.0.7680.164 and Signal version > 8.4.1 — OR, if nixpkgs-unstable hasn't moved, verify `nix-channel --list` timestamp has advanced and versions match current nixpkgs
- [ ] `which google-chrome-stable` on gement02 resolves to `~/.nix-profile/bin/google-chrome-stable` (not `/usr/bin/`)
- [ ] Repeat all above verifications on gement03
- [ ] gement01 is NOT restarted during verification (PO's live session); it picks up the fix on PO's next restart
- [ ] `07-apps.sh` logs before/after versions for Chrome and Signal
- [ ] `07-apps.sh` reports per-step pass/fail with exit codes
- [ ] All new tests in `10-tests.sh` pass on gement02 and gement03
- [ ] `docs/STARTUP_SCRIPTS.md` updated to reflect `011_bootstrap.sh`
- [ ] All changes committed to repo and verified through full teardown/setup pipeline

## Out of Scope

- Changing the Nix channel from `nixpkgs-unstable` to a pinned release (PO accepts the few-days lag behind vendor releases)
- Updating Chrome/Signal to specific target versions (the fix restores the update mechanism; actual versions depend on nixpkgs-unstable state at rebuild time)
- Changes to other boot scripts (01-nix through 06b-tmux, 07a-lang-deps, 07b-languages, 08-workspaces, 09-wofi, 09-snippets) — they all use `runuser` and will automatically benefit from the bootstrap reorder fix
- Adding retry logic or network resilience to 07-apps.sh (separate future enhancement)

## Dependencies

- F-0033 (Persistent bootstrap — introduced the 000_bootstrap.sh architecture)
- F-0028 (07-apps.sh — the boot script being hardened)
- Requires Docker image rebuild via Cloud Build (PE responsibility)
- Requires workstation stop/start cycle on gement02 and gement03 for verification

## Open Questions

- None — root cause confirmed, fix validated by PO, all decisions made.
