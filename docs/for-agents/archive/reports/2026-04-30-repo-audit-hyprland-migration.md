# Audit Report: NixOS Repository Post-Hyprland Migration

**Date:** 2026-04-30
**Host:** predator (x86_64-linux)
**NixOS Version:** 26.05.20260427.1c3fe55 (Yarara)
**Kernel:** 7.0.1
**nixpkgs:** 1c3fe55ad329cbcb28471bb30f05c9827f724c76
**Reference:** Live system is the source of truth.

---

## Executive Summary

This is a corrected audit. The initial pass produced significant noise. After revalidation, only **one real issue** was confirmed in the repo code. Everything else was either already resolved, upstream behavior outside repo control, or false positives from incorrect analysis methodology.

**Confirmed Issues:**
1. **NVIDIA kernel parameters duplicated** in `hardware/predator/hardware/gpu-nvidia.nix` — the module defines 3 params that the upstream NixOS NVIDIA module already injects automatically. Live `/proc/cmdline` proves duplication. (Medium severity)

**Already Resolved (by operator):**
2. Nix store GC was needed — operator ran GC after the audit, reclaiming ~21 GB (76 GB → 55 GB, 20,751 → 0 dead paths).

**Upstream / Not Repo Issues:**
3. ~25 `trace: Obsolete option ...` lines during `nix eval` — these originate from `nixpkgs` internal module aliases (`mkRenamedOptionModule`), not from tracked repo files. Confirmed by `grep -r` returning zero matches across `modules/` and `hardware/`.

**False Positives (initial audit noise):**
4. "Stale flake inputs" — the operator uses Fish abbreviations (`npus`, `naus`, `ncus`) that always run `nix flake update` before switch. The lockfile ages observed were a point-in-time snapshot, not neglect.
5. "1,194 duplicate packages across system/HM closures" — after rigorous manual audit of all 5 files that declare `environment.systemPackages`, zero packages are explicitly declared in both system and HM. The overlap is purely transitive dependencies (glibc, gtk, etc.), which is normal Nix behavior.

---

## 1. Confirmed Drift: NVIDIA Kernel Parameters

### 1.1 Finding

The live kernel command line (`/proc/cmdline`) contained duplicate NVIDIA parameters at the time of audit:

```
      2 nvidia-drm.fbdev=1
      2 nvidia-drm.modeset=1
      2 nvidia.NVreg_PreserveVideoMemoryAllocations=1
      1 nvidia.NVreg_UseKernelSuspendNotifiers=1
```

### 1.2 Root Cause

`hardware/predator/hardware/gpu-nvidia.nix` manually set:

```nix
boot.kernelParams = [
  "nvidia-drm.modeset=1"
  "nvidia-drm.fbdev=1"
  "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
];
```

The upstream NixOS NVIDIA module already injected these same three parameters automatically because the repo also set:

- `hardware.nvidia.modesetting.enable = true` → upstream injects `nvidia-drm.modeset=1`
- `hardware.nvidia.modesetting.enable = true` + driver ≥ 545 → upstream injects `nvidia-drm.fbdev=1`
- `hardware.nvidia.powerManagement.enable = true` → upstream injects `nvidia.NVreg_PreserveVideoMemoryAllocations=1`

### 1.3 Resolution

**Removed** the manual `boot.kernelParams` from `hardware/predator/hardware/gpu-nvidia.nix`. Post-edit `nix eval` confirmed each NVIDIA param appears exactly once in the generated `boot.kernelParams`.

| Check | Result |
|-------|--------|
| `nix eval` boot.kernelParams | 4 unique NVIDIA params (was 7 with duplicates) |
| `nix build` | PASS |
| `run-validation-gates.sh` | PASS |
| `check-repo-public-safety.sh` | PASS |

### 1.4 Resolution Confirmed

Post-reboot runtime validation (2026-04-29):

| Check | Result |
|-------|--------|
| Kernel params | 4 NVIDIA params, each exactly 1× |
| nvidia-smi | RTX 4060, driver 595.58.03, functional |
| Hyprland | PID 20020, running |
| hyprland-session.target | active |
| Wayland session | confirmed (loginctl Type=wayland) |
| VA-API | libva 1.22.0, nvidia driver backend |
| NVIDIA modules | nvidia, nvidia_drm, nvidia_modeset, nvidia_uvm loaded |

**Issue fully resolved.**

## 2. Resolved Issue: Nix Store Bloat

**Status:** Resolved by operator post-audit.

| Metric | Before | After |
|--------|--------|-------|
| Store size | 76 GB | **55 GB** |
| Dead paths | 20,751 | **0** |
| Store verify | Timeout (300s) | **Passed (<120s)** |

The operator ran `nix-collect-garbage -d`, reclaiming ~21 GB. Store integrity is confirmed.

---

## 3. Upstream Noise: Obsolete Option Traces

**Status:** Not a repo issue.

`nix eval` produces ~25 `trace: Obsolete option ...` lines. Examples:
```
trace: Obsolete option `boot.binfmtMiscRegistrations' is used.
trace: Obsolete option `boot.cleanTmpDir' is used.
trace: Obsolete option `boot.systemd.services' is used.
```

**Verification:** `grep -rE 'binfmtMiscRegistrations|cleanTmpDir|systemd\.services' modules/ hardware/` returned **zero matches**. The traces originate from `nixpkgs/lib/modules.nix` internal `mkRenamedOptionModule` aliases, which fire when any nixpkgs internal module (not repo code) references the old option names.

**Recommendation:** No repo action needed. If the noise is bothersome, filter eval stderr. If persistent across nixpkgs updates, report upstream.

---

## 4. False Positive Retractions

### 4.1 "Stale Flake Inputs"

Retracted. The operator's Fish abbreviations (`npus`, `naus`, `ncus`) always execute `nix flake update` before `nh os switch`. The lockfile is refreshed continuously as part of normal operations. Observing old commit dates in a lockfile snapshot does not indicate neglect when the operator actively updates.

### 4.2 "1,194 Duplicate Packages"

Retracted. After manually inspecting all 5 files that declare `environment.systemPackages` (`networking-wireguard-client.nix`, `networking-wireguard-server.nix`, `packages-system-tools.nix`, `packages-server-tools.nix`, `predator.nix`) and cross-referencing against all 22 files that declare `home.packages`, **zero packages are explicitly declared in both**. The overlap is purely transitive dependencies shared between the system closure and HM closure — expected and correct behavior.

### 4.3 "Tool Proliferation"

Retracted as an "issue". Multiple terminals, browsers, and editors are intentional for a developer workstation. The audit incorrectly flagged these as problems rather than noting them as observations.

---

## 5. Architecture Validation (All Passing)

| Check | Result |
|-------|--------|
| Validation gates (`run-validation-gates.sh`) | PASS |
| Docs drift (`check-docs-drift.sh`, 168 refs) | PASS |
| Flake check (`nix flake check`) | PASS |
| No `specialArgs` / `extraSpecialArgs` in `modules/` | PASS |
| No hardcoded usernames in tracked files | PASS |
| No `openssh.authorizedKeys.keys` in tracked hosts | PASS |
| No orphan publishers (all published modules consumed) | PASS |
| No `environment.systemPackages` in `hardware/` | PASS |
| Dendritic pattern respected | PASS |

---

## 6. Live System Consistency

| Aspect | Repo | Live | Status |
|--------|------|------|--------|
| Impermanence (btrfs subvols) | `@root`, `@persist`, `@nix`, `@home`, `@log`, `@swap` | Matches | OK |
| sysctl tuning | `swappiness=100`, `vfs_cache_pressure=50`, `tcp_bbr`, etc. | Matches | OK |
| ZRAM | `zstd`, 50%, 15.5G | Matches | OK |
| CPU governor | `powersave` | `powersave` | OK |
| SSH hardening | pubkey-only, restricted algos | Matches | OK |
| Firewall | TCP 22 only | Matches | OK |
| Tailscale mesh | 5 nodes | 5 nodes | OK |
| NVIDIA kernel params | 3 params manual + 3 upstream | 6 total (3 dup) | **DRIFT** |

---

## 7. Corrected Recommendations

1. **Remove duplicate NVIDIA kernel params** from `hardware/predator/hardware/gpu-nvidia.nix`. This is the only code change needed.
2. **No action on flake inputs** — operator already updates via workflow abbreviations.
3. **No action on system/HM overlap** — the overlap is transitive deps, not explicit duplication.
4. **No action on tool proliferation** — intentional developer workstation setup.
5. **No action on obsolete option traces** — upstream nixpkgs issue.

---

*Corrected audit. Initial report contained false positives from flawed methodology. This version reflects only confirmed, reproducible findings.*
