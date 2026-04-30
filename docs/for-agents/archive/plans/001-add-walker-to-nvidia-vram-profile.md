# Add Walker to NVIDIA VRAM Profile

## Goal

Add the Walker launcher to the NVIDIA application profile that limits free buffer
pool VRAM usage on Wayland compositors and related applications, using the same
mechanism already applied to Hyprland, Code, and Xwayland.

## Scope

In scope:
- Add `.walker-wrapped` procname match to `50-wayland-vram-fix.json` in
  `hardware/predator/hardware/gpu-nvidia.nix`.
- Validate the change with `nix eval` to confirm the generated JSON includes
  the new rule.
- Build and run validation gates.

Out of scope:
- Changes to walker configuration or behavior.
- Changes to other NVIDIA application profiles.
- Any changes outside `hardware/predator/hardware/gpu-nvidia.nix`.

## Current State

- `hardware/predator/hardware/gpu-nvidia.nix` defines an NVIDIA application
  profile at `environment.etc."nvidia/nvidia-application-profiles-rc.d/50-wayland-vram-fix.json"`.
- The profile currently matches three procs:
  - `.Hyprland-wrapped`
  - `code`
  - `Xwayland`
- All matched procs receive `GLVidHeapReuseRatio = 0`, which limits NVIDIA's
  free buffer pool and prevents VRAM bloat on long-running Wayland sessions.
- Walker is a GTK4 + layer-shell Wayland launcher that runs as a persistent
  service (`walker --gapplication-service`). It creates GPU buffers every time
  it opens and could benefit from the same VRAM limit.
- Live system investigation confirms the walker process name is `.walker-wrapped`
  (read from `/proc/<pid>/comm`), matching the `.Hyprland-wrapped` pattern.

## Desired End State

- `50-wayland-vram-fix.json` contains a fourth rule matching `.walker-wrapped`.
- `nix eval` confirms the generated config includes the new procname.
- Build succeeds, validation gates pass.
- No regression in existing rules.

## Phases

### Phase 0: Baseline

Capture the current state of the NVIDIA application profile.

Validation:
- `nix eval path:$PWD#nixosConfigurations.predator.config.environment.etc."nvidia/nvidia-application-profiles-rc.d/50-wayland-vram-fix.json".text | jq '.rules | length'`
  - Expected: 3 rules.
- `nix eval ... | jq '.rules[].pattern.matches'`
  - Expected: `[".Hyprland-wrapped", "code", "Xwayland"]`.
- `ps aux | grep walker | grep -v grep` confirms walker is running.
- `cat /proc/$(pgrep walker)/comm` confirms `.walker-wrapped`.

### Phase 1: Add Walker Rule

Targets:
- `hardware/predator/hardware/gpu-nvidia.nix`

Changes:
- Insert a new rule object after the Xwayland rule (or in any position within
  the `rules` list) with:
  ```nix
  {
    pattern = {
      feature = "procname";
      matches = ".walker-wrapped";
    };
    profile = "Limit Free Buffer Pool On Wayland Compositors";
  }
  ```

Validation:
- `nix eval` shows 4 rules.
- `nix eval` shows `.walker-wrapped` in the matches list.
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel` succeeds.
- `bash scripts/run-validation-gates.sh` passes.
- `./scripts/check-repo-public-safety.sh` passes.

Diff expectation:
```diff
--- a/hardware/predator/hardware/gpu-nvidia.nix
+++ b/hardware/predator/hardware/gpu-nvidia.nix
@@ -57,6 +57,13 @@
             profile = "Limit Free Buffer Pool On Wayland Compositors";
           }
           {
+            pattern = {
+              feature = "procname";
+              matches = ".walker-wrapped";
+            };
+            profile = "Limit Free Buffer Pool On Wayland Compositors";
+          }
+          {
             pattern = {
               feature = "procname";
               matches = "Xwayland";
```

Commit target:
- `fix(hardware/predator): add walker to nvidia vram profile`

## Risks

- **False positive procname**: If `/proc/<pid>/comm` is unreliable for the NVIDIA
  driver's procname matching, the rule may not take effect. Mitigation: the same
  method (`/proc/<pid>/comm`) was used to identify `.Hyprland-wrapped`, which is
  confirmed working. If the driver uses a different name source (e.g. argv[0]),
  we can adjust after runtime verification.
- **No observable change**: `GLVidHeapReuseRatio = 0` is a preventative setting;
  there may be no immediately observable difference in VRAM usage. This is
  acceptable — the setting is standard practice for Wayland apps on NVIDIA.

## Definition of Done

- [x] `.walker-wrapped` appears in the `rules` list of `50-wayland-vram-fix.json`.
- [x] `nix eval` confirms 4 rules with `.walker-wrapped` as one match.
- [x] `nix build` succeeds.
- [x] `run-validation-gates.sh` passes.
- [x] `check-repo-public-safety.sh` passes.
- [x] Commit follows conventional format: `fix(hardware/predator): ...`
