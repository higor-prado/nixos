# Fix NVIDIA Kernel Parameter Duplication

## Goal

Remove the three redundant NVIDIA kernel parameters from `hardware/predator/hardware/gpu-nvidia.nix`. The upstream NixOS NVIDIA module already injects them automatically based on the existing `hardware.nvidia.*` options. The live system currently shows each parameter duplicated in `/proc/cmdline`.

## Scope

In scope:
- Remove `boot.kernelParams` from `hardware/predator/hardware/gpu-nvidia.nix`
- Verify the fix by evaluating the generated `boot.kernelParams`
- Build the predator configuration to prove no regression
Out of scope:
- Touching any other file
- Changing `hardware.nvidia.*` options (they are correct and trigger upstream injection)
- Touching session variables, NVIDIA profiles, or graphics settings
- Updating flake inputs (operator already does this via `npus`/`naus`/`ncus` workflow)
- Any other audit findings (all revalidated as false positives or upstream noise)

## Current State

`hardware/predator/hardware/gpu-nvidia.nix` lines 23-27:
```nix
boot.kernelParams = [
  "nvidia-drm.modeset=1"
  "nvidia-drm.fbdev=1"
  "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
];
```

The upstream NixOS NVIDIA module (`nixpkgs/nixos/modules/hardware/video/nvidia.nix`) already injects these three parameters because the repo sets:
- `hardware.nvidia.modesetting.enable = true` → upstream injects `nvidia-drm.modeset=1`
- `hardware.nvidia.modesetting.enable = true` + driver ≥ 545 → upstream injects `nvidia-drm.fbdev=1`
- `hardware.nvidia.powerManagement.enable = true` → upstream injects `nvidia.NVreg_PreserveVideoMemoryAllocations=1`

Live `/proc/cmdline` confirms duplication:
```
      2 nvidia-drm.fbdev=1
      2 nvidia-drm.modeset=1
      2 nvidia.NVreg_PreserveVideoMemoryAllocations=1
      1 nvidia.NVreg_UseKernelSuspendNotifiers=1   ← only upstream, unduplicated
```

- `gpu-nvidia.nix` contains no `boot.kernelParams` attribute.
- `nix eval` of predator's `boot.kernelParams` shows each NVIDIA param exactly once.
- `nix build` of predator configuration succeeds.
- Validation gates pass.
- Live `/proc/cmdline` after next switch shows each NVIDIA param exactly once.
- NVIDIA runtime remains fully functional after switch (driver loaded, GPU visible, display compositor running, VA-API working).
## Phases

### Phase 0: Baseline

Validation:
```bash
# Confirm current duplication
nix eval path:$PWD#nixosConfigurations.predator.config.boot.kernelParams | grep nvidia
# Expected: each of the 3 params appears twice

bash scripts/run-validation-gates.sh
# Expected: passes
```

### Phase 1: Remove Redundant Kernel Params

Target: `hardware/predator/hardware/gpu-nvidia.nix`

Change: Delete the entire `boot.kernelParams` attribute (lines 23-27). Keep everything else in the file untouched.

Validation:
```bash
# Confirm params are now single
nix eval path:$PWD#nixosConfigurations.predator.config.boot.kernelParams | grep nvidia
# Expected: each param appears exactly once

# Build to prove no regression
nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel

# Run gates
bash scripts/run-validation-gates.sh
# Expected: passes
Rollback path: Revert the commit. The change is a pure removal of lines that duplicate upstream behavior; reverting simply restores the old (duplicated) state without breaking anything.

### Phase 2: Runtime Validation (Post-Switch)

This phase validates that removing the manual kernel params did not break NVIDIA functionality at runtime. It runs **after** `nh os switch`.

Pre-switch baseline capture (run once before switch):
```bash
# Save baseline for comparison
nvidia-smi --query-gpu=driver_version,name,temperature.gpu,utilization.gpu --format=csv > /tmp/nvidia-baseline.txt
lsmod | grep -E '^nvidia' > /tmp/nvidia-modules-baseline.txt
vainfo 2>/dev/null | head -n 5 > /tmp/vaapi-baseline.txt || echo "vainfo not available" > /tmp/vaapi-baseline.txt
pgrep -x Hyprland > /dev/null && echo "Hyprland running" > /tmp/compositor-baseline.txt || echo "Hyprland NOT running" > /tmp/compositor-baseline.txt
echo "$WAYLAND_DISPLAY" > /tmp/wayland-baseline.txt
```

Post-switch validation (run after reboot or switch):
```bash
# 1. Kernel params
cat /proc/cmdline | tr ' ' '\n' | grep nvidia | sort | uniq -c
# Expected: each of modeset, fbdev, PreserveVideoMemoryAllocations appears exactly once

# 2. NVIDIA kernel modules loaded
cat /tmp/nvidia-modules-baseline.txt
lsmod | grep -E '^nvidia'
# Expected: same modules loaded (nvidia, nvidia_drm, nvidia_modeset, nvidia_uvm)

# 3. nvidia-smi works
nvidia-smi
# Expected: shows GPU info, no errors, driver version matches baseline

# 4. Compositor still running
pgrep -x Hyprland
# Expected: returns PID (non-empty)

# 5. Wayland session active
echo "$WAYLAND_DISPLAY"
# Expected: non-empty (e.g., wayland-1)

# 6. VA-API (optional but good signal)
vainfo 2>/dev/null | head -n 5
# Expected: no errors, shows NVIDIA driver backend

# 7. Compare with baseline
# If any check above fails, immediately rollback:
#   sudo nixos-rebuild switch --rollback
#   # or select previous generation in bootloader
```

**Rollback on failure:** If any runtime check fails (module not loaded, nvidia-smi errors, compositor not running), the previous generation is known-good. Roll back immediately:
```bash
sudo nixos-rebuild switch --rollback
```

Or reboot and select the previous generation from GRUB.

### Phase 3: Confirm & Archive

- Update the audit report to mark this issue as resolved.
- Move this plan to `docs/for-agents/archive/plans/` when the work is complete.

## Risks

- **Risk (negligible):** The upstream module stops injecting one of these params in a future nixpkgs revision. Mitigation: This would be a breaking upstream change affecting all NixOS NVIDIA users. It would be fixed upstream, not in this repo.
- **Risk (negligible):** A future nixpkgs revision changes the parameter name. Mitigation: Same as above — upstream change, upstream fix.
- **Risk (low):** A param is removed from the upstream module in the *same* nixpkgs revision used for this switch, and we also remove it from the repo, resulting in the param being missing entirely. Mitigation: The `nix eval` check in Phase 1 confirms the param is still present in the generated config *before* the switch. If `nix eval` shows the param is missing, do not proceed.
## Definition of Done

- [x] `hardware/predator/hardware/gpu-nvidia.nix` no longer contains `boot.kernelParams`.
- [x] `nix eval path:$PWD#nixosConfigurations.predator.config.boot.kernelParams` shows each NVIDIA param exactly once.
- [x] `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel` succeeds.
- [x] `bash scripts/run-validation-gates.sh` passes.
- [x] `./scripts/check-repo-public-safety.sh` passes.
- [x] After `nh os switch`, live `/proc/cmdline` shows each NVIDIA param exactly once.
- [x] Runtime validation passes: `nvidia-smi` works, Hyprland is running, `WAYLAND_DISPLAY` is set, NVIDIA kernel modules are loaded.
- [x] Plan moved to archive.
---

## Audit Context

This plan was created as the sole follow-up to a corrected audit report (`docs/for-agents/archive/reports/2026-04-30-repo-audit-hyprland-migration.md`). The initial audit produced false positives regarding stale flake inputs, system/HM package duplication, and tool proliferation. All were revalidated and retracted. The NVIDIA param duplication is the only confirmed code issue.

The operator's workflow already handles flake input updates via Fish abbreviations (`npus`, `naus`, `ncus`) that run `nix flake update` before every switch. No lockfile maintenance action is needed.

*Plan written following `docs/for-agents/plans/000-plan-scaffold.md`.*


---

## Runtime Validation Rationale

Removing kernel params that duplicate upstream injection is theoretically safe, but kernel command line changes affect early boot driver initialization. The params involved (`modeset=1`, `fbdev=1`, `PreserveVideoMemoryAllocations=1`) control DRM framebuffer allocation and suspend/resume VRAM handling. A regression could manifest as:

- Black screen after boot (modeset/fbdev failure)
- Suspend/resume corruption (PreserveVideoMemoryAllocations failure)
- Hyprland failing to start (DRM device unavailable)

The Phase 2 runtime checks catch these immediately by verifying:
1. **Kernel params are present** (Phase 2 check 1) — confirms upstream injection still works
2. **Modules loaded** (check 2) — confirms driver initialized
3. **nvidia-smi functional** (check 3) — confirms userspace driver communication
4. **Compositor alive** (check 4) — confirms display pipeline works end-to-end
5. **Wayland display set** (check 5) — confirms session environment intact
6. **VA-API** (check 6) — confirms video acceleration path

If any check fails, rollback is one command away.