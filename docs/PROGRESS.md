# Development Progress Log — Cloud Workstation

## Session 1

### Goals
- Initial project setup and configuration

### Completed
- Generated project scaffolding with appteam
  - CLAUDE.md with team workflow, conventions, and pipeline rules
  - Agent definitions for PM, TPM, SWE-1, SWE-2, SWE-3, SWE-Test, SWE-QA, Platform Engineer, Reviewer
  - BACKLOG.md, PROGRESS.md, RELEASENOTES.md

### Next Steps
- Define initial feature backlog in BACKLOG.md
- Begin implementation of first milestone

---

## Session 2 — 2026-03-20

### Goals
- Execute Milestone 1: Stand up the Cloud Workstation with GPU, Antigravity, GNOME, noVNC

### Pre-existing State (discovered at session start)
- F-0001 (Cluster): `workstation-cluster` already exists in us-west1 — DONE
- F-0002 (Artifact Registry): `workstation-images` repo exists in us-west1 with images — DONE
- F-0003 (Docker Image): `workstation` image built and pushed (~3.3GB) with GNOME, Antigravity, Chrome, TigerVNC, noVNC — DONE
- All required APIs enabled (workstations, artifactregistry, compute)
- No SA key file found; using admin@ameerabbas.altostrat.com identity

### Completed
- **F-0001** (Cluster): Pre-existing `workstation-cluster` in us-west1
- **F-0002** (Artifact Registry): Pre-existing `workstation-images` repo in us-west1
- **F-0003** (Docker Image): Pre-existing `workstation` image (~3.3GB) with GNOME, Antigravity, Chrome, TigerVNC, noVNC
- **F-0004/F-0005** (Config): Created `ws-config` — n1-standard-16 + nvidia-tesla-t4, 500GB pd-ssd, 4h idle/12h run, no public IP, Shielded VM
- **F-0006** (GPU): Tesla T4 verified — Driver 535.288.01, CUDA 12.2, nvidia-smi at `/var/lib/nvidia/bin/`. Created `/etc/profile.d/nvidia.sh` for PATH/LD_LIBRARY_PATH
- **F-0007** (Nix): Nix 2.34.2 installed on persistent HOME disk. `nix-env -iA` works. Created Cloud Router `ws-router` + Cloud NAT `ws-nat` for internet access
- **F-0008** (IAM/Network): admin@ameerabbas.altostrat.com has workstations.user. AR reader granted to service agent. No public IP + Shielded VM (org policies). ameer00@gmail.com access pending (API precondition issue — can be set when workstation is stopped)
- **F-0009** (Workstation): `dev-workstation` RUNNING at `dev-workstation.cluster-wg3q6vm6rnflcvjsrq5k7aqoac.cloudworkstations.dev`
- **F-0010** (E2E): All verified — Antigravity installed, noVNC active (HTTP 302 via proxy), TigerVNC active, T4 GPU working, Nix 2.34.2 with package install, 492GB home disk available

### Issues Encountered and Resolved
1. `--idle-timeout=14400s` invalid — int expected, no suffix — FIXED
2. `g2-standard-16` NOT supported by Cloud Workstations — used `n1-standard-16` + `nvidia-tesla-t4` instead
3. `nvidia-l4` accelerator NOT supported — used `nvidia-tesla-t4` (T4 16GB VRAM)
4. `roles/workstations.user` cannot be bound at project level — granted at workstation level automatically on create
5. Org policy `constraints/compute.vmExternalIpAccess` — added `--disable-public-ip-addresses`
6. Org policy `constraints/compute.requireShieldedVm` — added `--shielded-secure-boot --shielded-vtpm --shielded-integrity-monitoring`
7. No internet inside workstation — created Cloud Router + Cloud NAT
8. `nvidia-smi` not in PATH — found at `/var/lib/nvidia/bin/`, created profile script
9. `owner-sa` service account does not exist — not critical, skipped

### Decisions
- Used admin@ameerabbas.altostrat.com identity (no SA key file)
- Machine type: n1-standard-16 (60GB RAM) since g2-standard-16 not supported by Cloud Workstations
- GPU: nvidia-tesla-t4 since nvidia-l4 not supported as accelerator
- Cloud NAT for internet access (required due to no public IP org policy)

### Next Steps
- Grant ameer00@gmail.com access (stop workstation, set IAM, restart)
- Test stop/start cycle to verify persistence (Nix, GPU profile, data)
- Tag v1.0 release after PO approval
