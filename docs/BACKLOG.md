# Project Backlog — Cloud Workstation

**Maintained by:** TPM
**Last updated:** 2026-03-20

---

## How to Read This Backlog

- **ID:** Unique feature identifier (`F-0001`, `F-0002`, etc.) — sequential across all milestones, never reused
- **Priority:** P0 (critical path), P1 (important), P2 (nice to have)
- **Status:** `backlog` | `in-progress` | `in-review` | `done` | `blocked`
- **Owner:** Assigned team member
- **Branch:** Git feature branch
- **Dependencies:** Other feature IDs that must complete first
- **Feedback:** Review notes, blockers, decisions — updated as work progresses

---

## Current Milestone — Milestone 1: Cloud Workstation v1.0

| ID | Feature | Spec | Priority | Status | Owner | Branch | Dependencies | Feedback |
|----|---------|------|----------|--------|-------|--------|--------------|----------|
| F-0001 | Cloud Workstation Cluster (us-west1) | F-0001 | P0 | done | PE | feature/ws-cluster | — | Cluster `workstation-cluster` created 2026-03-20 |
| F-0002 | Artifact Registry repository | F-0001 | P0 | done | PE | feature/ws-registry | — | `workstation-images` repo created, Docker format, us-west1 |
| F-0003 | Custom Docker image (Dockerfile) | F-0001 | P0 | done | SWE-1 | feature/ws-dockerfile | F-0002 | Image `workstation` pushed (~3.3GB), includes GNOME+Antigravity+Chrome+VNC+noVNC |
| F-0004 | Workstation Config (GPU) | F-0001 | P0 | done | PE | feature/ws-config | F-0001, F-0003 | Config `ws-config` created: n1-standard-16 + nvidia-tesla-t4, 500GB pd-ssd, 4h idle/12h run, no public IP (org policy) |
| F-0005 | Persistent disk setup (500GB SSD, HOME) | F-0001 | P0 | done | PE | feature/ws-disk | F-0004 | 500GB pd-ssd configured in ws-config via --pd-disk-size=500 --pd-disk-type=pd-ssd |
| F-0006 | GPU driver verification (T4) | F-0001 | P0 | done | PE | feature/ws-gpu-drivers | F-0009 | Tesla T4 verified, Driver 535.288.01, CUDA 12.2. nvidia-smi at /var/lib/nvidia/bin/. Profile script created. |
| F-0007 | Nix package manager (persistent disk) | F-0001 | P1 | done | PE | feature/ws-nix | F-0009 | Nix 2.34.2 installed on persistent disk. nix-env works. Cloud Router + NAT created for internet. |
| F-0008 | Network and IAM configuration | F-0001 | P0 | done | PE | feature/ws-iam | F-0001 | admin@ameerabbas.altostrat.com has workstations.user. AR reader granted. ameer00@gmail.com pending (API precondition). No public IP, Shielded VM enabled. |
| F-0009 | Workstation creation and VNC setup | F-0001 | P0 | done | PE | feature/ws-create | F-0004, F-0008 | dev-workstation RUNNING. Host: dev-workstation.cluster-wg3q6vm6rnflcvjsrq5k7aqoac.cloudworkstations.dev |
| F-0010 | End-to-end validation | F-0001 | P0 | done | SWE-QA | — | F-0009, F-0006, F-0007 | All verified: Antigravity installed, noVNC active (HTTP 302 via proxy), T4 GPU working, Nix 2.34.2 with package install, 492GB home disk |

---

## Milestone 2: Nix App Migration

| ID | Feature | Spec | Priority | Status | Owner | Branch | Dependencies | Feedback |
|----|---------|------|----------|--------|-------|--------|--------------|----------|
| F-0011 | Reboot workstation with new image | F-0011 | P0 | in-progress | PE | — | — | Image rebuilt with 200_persist-nix.sh. Stopping workstation to pick up new image. |
| F-0012 | Set up Nix Home Manager (user + root) | F-0017 | P0 | backlog | SWE-1 | — | F-0011 | Declarative config at ~/.config/home-manager/home.nix. Both user and root. |
| F-0013 | Verify Antigravity persistent install | F-0011 | P0 | backlog | SWE-1 | — | F-0011 | Already at ~/.antigravity. Verify launches after reboot. Proprietary, not in nixpkgs. |
| F-0014 | Install browsers via Nix HM (Chromium, Chrome) | F-0017 | P0 | backlog | SWE-1 | — | F-0012 | nixpkgs.chromium, nixpkgs.google-chrome. Desktop shortcuts with --no-sandbox flags. |
| F-0015 | Install dev tools via Nix HM (neovim, tmux, tree, zsh, ffmpeg) | F-0017 | P0 | backlog | SWE-1 | — | F-0012 | Set zsh as default shell. Neovim with custom init.lua (docs/specs/neovim-config/init.lua). All via Home Manager. |
| F-0016 | Install Sway + Waybar + supporting apps via Nix HM | F-0016 | P0 | backlog | SWE-2 | — | F-0012 | 8 workspaces, waybar, foot, wofi, thunar, clipman. VNC compat. Full keybinding config (CTRL+SHIFT modifier). |
| F-0017 | Install IDEs via Nix HM (VSCode, IntelliJ, Cursor) | F-0017 | P0 | backlog | SWE-2 | — | F-0012 | nixpkgs.vscode, nixpkgs.jetbrains.idea-community. Cursor may need AppImage/custom deriv. |
| F-0018 | Install AI CLI tools via Nix (Claude Code, Gemini CLI) | F-0017 | P0 | backlog | SWE-3 | — | F-0012 | May need nodejs + npm global install. claude-code via npm, gemini-cli via npm. |
| F-0019 | Post-reboot E2E validation | F-0011 | P0 | backlog | SWE-QA | — | F-0013 thru F-0018 | All apps survive stop/start cycle. Nix HM, Sway, all apps, GPU, noVNC. |

---

## Future Items

| ID | Feature | Spec | Priority | Status | Owner | Branch | Dependencies | Feedback |
|----|---------|------|----------|--------|-------|--------|--------------|----------|
| | | | | | | | | |

---

## Team Roster

| Role | Agent | Specialty |
|------|-------|-----------|
| PM | PM | Product requirements & PO communication |
| TPM | TPM | Backlog, coordination & progress tracking |
| SWE-1 | SWE-1 | General Engineer 1 |
| SWE-2 | SWE-2 | General Engineer 2 |
| SWE-3 | SWE-3 | General Engineer 3 |
| SWE-Test | SWE-Test | Automated testing & coverage |
| SWE-QA | SWE-QA | E2E testing & QA |
| Platform | Platform Engineer | Infrastructure & deployment |
| Reviewer | Reviewer | Code review & quality |
