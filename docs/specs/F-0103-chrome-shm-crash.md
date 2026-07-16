# F-0103: Chrome renderer crashes on heavy pages (missing --disable-dev-shm-usage)

**Type:** Bug
**Priority:** P0 (critical)
**Status:** Approved
**Requested by:** PO
**Date:** 2026-07-16

## Problem

After v1.17 (F-0083) removed apt Chrome from the Docker image, the only Chrome is Nix `google-chrome`. The old apt install included a dpkg-divert wrapper that injected `--no-sandbox --no-zygote --disable-gpu --disable-dev-shm-usage` into every launch. The Nix Chrome launches bare — no flags are injected.

The container's `/dev/shm` is 64 MB. Chrome renderer processes crash on memory-heavy pages (e.g., Chrome Web Store) because the default shm-backed mmap exhausts this space. Without `--disable-dev-shm-usage`, Chrome falls back to `/dev/shm` instead of `/tmp`, causing renderer OOM crashes.

**A/B evidence (PO-verified on gement01):**
- `google-chrome-stable --headless --dump-dom https://chromewebstore.google.com` → 0 bytes output, 5 crash errors
- `google-chrome-stable --headless --dump-dom --disable-dev-shm-usage https://chromewebstore.google.com` → 1 MB DOM, 0 errors
- Sway `$mod+b` binding (passes `--disable-dev-shm-usage`) works — PO's interim workaround

## Root Cause

Nix `google-chrome` package creates a shell wrapper at `~/.nix-profile/bin/google-chrome-stable` but does not inject any flags. The Nix `commandLineArgs` override mechanism (`google-chrome.override { commandLineArgs = "..."; }`) bakes flags into this wrapper at the Nix expression level.

## Requirements

### R1: Nix package override in home.nix (all three machines)

1. In `~/.config/home-manager/home.nix` on gement01, gement02, and gement03, replace the bare `google-chrome` package with:
   ```nix
   (google-chrome.override { commandLineArgs = "--disable-dev-shm-usage"; })
   ```
2. Apply the same override to `chromium` for consistency (same 64 MB `/dev/shm` constraint):
   ```nix
   (chromium.override { commandLineArgs = "--disable-dev-shm-usage"; })
   ```
3. Run `home-manager switch` on each machine. No reboot required — the wrapper is regenerated immediately.

### R2: Update `scripts/cloud-build-setup.sh` for fresh setups

1. In the `BASE_PKGS` variable (line ~484), replace `chromium google-chrome` with the override expressions.
2. Since `BASE_PKGS` is a space-separated string fed into a Nix list template, the overrides must be injected differently — the Nix `(pkg.override { ... })` syntax cannot appear as a bare word in the package list. Instead:
   - Remove `chromium` and `google-chrome` from `BASE_PKGS`
   - Add the override expressions directly into the `home.packages` heredoc template (after the `${NIX_PKG_LIST}` interpolation), e.g.:
     ```nix
     home.packages = with pkgs; [
       ${NIX_PKG_LIST}
       (google-chrome.override { commandLineArgs = "--disable-dev-shm-usage"; })
       (chromium.override { commandLineArgs = "--disable-dev-shm-usage"; })
     ];
     ```

### R3: Boot test in `workstation-image/boot/10-tests.sh`

1. Add a test that asserts the Nix wrapper for `google-chrome-stable` contains `--disable-dev-shm-usage`:
   ```bash
   CHROME_WRAPPER=$(runuser -u $USER -- bash -c ". $NIX_SH && which google-chrome-stable" 2>/dev/null)
   if [ -n "$CHROME_WRAPPER" ] && grep -q "\-\-disable-dev-shm-usage" "$CHROME_WRAPPER"; then
       test_pass "Chrome wrapper includes --disable-dev-shm-usage"
   else
       test_fail "Chrome wrapper missing --disable-dev-shm-usage"
   fi
   ```
2. Same for `chromium`.
3. **Constraint:** gement01's live `10-tests.sh` has unmerged Antigravity-2.0 test content from `feature/composable-install`. The repo edit is authoritative. SWE/PE deploying to gement01 must NOT blindly overwrite the live file — merge or append only.

### R4: Verify on all three machines

1. After `home-manager switch`, run the A/B headless test:
   ```bash
   google-chrome-stable --headless --dump-dom https://chromewebstore.google.com 2>/dev/null | wc -c
   ```
   Must return > 0 bytes without any explicit `--disable-dev-shm-usage` flag (wrapper supplies it).
2. Verify the wrapper contains the flag:
   ```bash
   grep -- '--disable-dev-shm-usage' "$(which google-chrome-stable)"
   ```
3. PO confirms interactive Chrome works from wofi launcher on gement01.

## Acceptance Criteria

- [ ] `~/.nix-profile/bin/google-chrome-stable` wrapper contains `--disable-dev-shm-usage` on all 3 machines
- [ ] `~/.nix-profile/bin/chromium` wrapper contains `--disable-dev-shm-usage` on all 3 machines
- [ ] Headless `--dump-dom` of chromewebstore.google.com succeeds (>0 bytes) WITHOUT explicit flag on all 3 machines
- [ ] `scripts/cloud-build-setup.sh` generates home.nix with the override (survives teardown+setup)
- [ ] Boot test in `10-tests.sh` passes for both Chrome and Chromium wrappers
- [ ] PO confirms interactive Chrome from wofi on gement01 loads Chrome Web Store without crashes

## Out of Scope

- `--no-sandbox` — sandbox works in the container; not adding
- `--disable-gpu` — GPU rendering TBD; not adding unless PO reports residual glitches post-fix (contingency only)
- `--no-zygote` — no evidence of need
- F-0102 (home.nix single source of truth) — this fix increases its urgency but does not expand into it; the live home.nix edits here are a stopgap until F-0102 lands

## Dependencies

- F-0083 (v1.17, merged) — root cause: removed apt Chrome
- F-0102 (backlog) — urgency increased by this fix; home.nix still has manual drift across machines

## Open Questions

- None — root cause proven, fix direction approved by PO
