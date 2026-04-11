# Predator Gaming Return Plan

## Goal

Restore a measured, low-risk gaming path on `predator` so simple and moderate
games can be installed and run with the best practical Linux performance this
repo can support, while keeping ownership aligned with the repo architecture
and avoiding a repeat of the earlier "add everything, then remove everything"
cycle.

## Scope

In scope:
- reintroduce a tracked gaming owner under `modules/features/desktop/`
- wire that owner back into `modules/hosts/predator.nix`
- restore the minimal Steam-first path needed for declarative game installs
- keep only the gaming/performance changes that have either:
  - already been validated in this repo, or
  - can be validated in small reversible slices now
- reuse the current `predator` performance and NVIDIA baseline where it is
  already helping
- document which historical changes were real wins, which were rejected, and
  which were only game-specific workarounds

Out of scope:
- chasing Windows parity for heavy AAA titles
- restoring `noctalia`, `flatpak`, or the old alternate desktop variant
- global aggressive governor or memory-policy changes already rejected by the
  benchmark history
- per-game hacks as baseline policy for the whole host
- BIOS, EC, undervolt, overclock, or fan-control experimentation
- anti-cheat compatibility work

## Current State

- `modules/hosts/predator.nix` currently has no `nixos.gaming` or
  `homeManager.gaming` import. The shared gaming owner was removed by
  `56b8ab0` (`feat(predator): remove gaming module`) and the remaining gaming
  references were cleaned up by `5eac6bf`
  (`feat(cleanup): remove noctalia, flatpak, and gaming remnants`).
- The useful host baseline for gaming still exists:
  - `hardware/predator/performance.nix` keeps `zramSwap`, `systemd.oomd`,
    explicit sysctls, `ananicy-cpp`, `intel_pstate=active`,
    `powerManagement.cpuFreqGovernor = "powersave"`, and Nix daemon idle
    scheduling.
  - `hardware/predator/hardware/gpu-nvidia.nix` keeps proprietary NVIDIA,
    32-bit graphics, Wayland/NVIDIA session variables, and the
    `GLVidHeapReuseRatio=0` application profile for `niri`,
    `xwayland-satellite`, and `Xwayland`.
- The benchmark log in
  `docs/for-agents/archive/log-tracks/020-performance-tuning-experiment-progress.md`
  already answered two important tuning questions:
  - `cpuFreqGovernor = "performance"` did not produce a meaningful win over the
    current `powersave` + `intel_pstate=active` + Acer
    `balanced-performance` platform profile, so it was rejected.
  - `vm.swappiness = 1` and `vm.swappiness = 30` were both benchmarked and
    rejected; they did not improve the measured runtime path.
  - the only explicit performance tuning that was kept from that experiment was
    the narrow `ananicy` rule prioritizing `keyrs`.
- The Steam/input cleanup from `3f57d00`
  (`fix(input): align fcitx and steam input method`) partly remains in the live
  repo:
  - `modules/features/desktop/fcitx5.nix` now owns a single `fcitx5` startup
    path and the modern Wayland frontend
  - `modules/features/desktop/theme-base.nix` still provides GTK IM fallback
    for legacy/XWayland apps
  - this means part of the Steam compatibility groundwork survived even after
    the gaming owner was removed
- The old gaming owner from `759db64`
  (`feat(predator): add gaming stack and persistence diagnostics`) was broad:
  Steam, Protontricks, GameMode, Gamescope, MangoHud, Heroic, Lutris,
  ProtonPlus, `steam-run`, and later `steam-tui`.
- The later Cyberpunk-specific work in `5e7b907`
  (`Optimize for gamings - before yolo`) mixed three classes of changes:
  - durable Steam/Proton environment changes
  - NVIDIA/XWayland VRAM behavior already retained in
    `hardware/predator/hardware/gpu-nvidia.nix`
  - per-game/per-monitor fixes in `config/desktops/dms-on-niri/custom.kdl`
    that should not define the baseline gaming stack
- The archived Cyberpunk plan shows the hard limit that must shape the new
  scope:
  - Linux/NVIDIA/Proton still trails Windows for `Cyberpunk 2077`
  - the DXR/RT path was blocked by a driver/runtime bug and needed `nodxr`
  - the fullscreen/focus fix depended on game config plus a specific Niri rule
  - conclusion: those fixes are evidence for targeted Proton/NVIDIA support,
    not evidence that the whole host should be tuned around Cyberpunk

## Desired End State

- `predator` again has a tracked gaming owner in
  `modules/features/desktop/gaming.nix`.
- The first restored slice is intentionally minimal and Steam-first:
  declarative Steam install, Protontricks, and only the narrow runtime pieces
  needed for the core path to work well on `predator`.
- The current host baseline in `hardware/predator/performance.nix` and
  `hardware/predator/hardware/gpu-nvidia.nix` remains the default foundation;
  previously rejected global tunings are not reintroduced.
- Steam-specific compatibility stays owned in the gaming feature, while
  keyboard/IM/GTK ownership remains where the repo already put it.
- Game-specific launch fixes stay opt-in and documented, not system-wide
  defaults.
- Optional launchers and overlays return only after the minimal Steam path is
  stable.
- Every slice is validated with the repo gates plus a real `predator` runtime
  check.

## Phases

### Phase 0: Freeze Baseline and Historical Decisions

Targets:
- this plan
- current `predator` runtime surface

Changes:
- no runtime config changes
- record the historical keep/reject matrix before reintroducing anything
- capture the current eval/build baseline for `predator`

Validation:
- `nix flake metadata`
- `nix eval path:$PWD#nixosConfigurations.predator.config.system.build.toplevel.drvPath`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.<user>.home.path`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`
- `./scripts/run-validation-gates.sh structure`

Diff expectation:
- no closure diff; documentation and baseline only

Commit target:
- none

### Phase 1: Restore the Minimal Shared Gaming Owner

Targets:
- `modules/features/desktop/gaming.nix`
- `modules/hosts/predator.nix`

Changes:
- recreate `flake.modules.nixos.gaming` and `flake.modules.homeManager.gaming`
- wire the feature explicitly into `predator`
- keep the first slice narrow:
  - `programs.steam.enable = true`
  - `programs.steam.protontricks.enable = true`
  - `programs.gamemode.enable = true`
  - `pkgs.mangohud`
- do not restore the whole old launcher/tooling bundle in the same slice
- do not make `gamescope` part of the mandatory baseline yet; Wayland + NVIDIA
  + Niri is too easy to muddy in the first pass

Validation:
- `./scripts/run-validation-gates.sh`
- `nix eval path:$PWD#nixosConfigurations.predator.config.programs.steam.enable`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.<user>.home.path`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`

Diff expectation:
- system closure gains Steam, Protontricks, GameMode, and their runtime
  dependencies
- home closure gains only the minimal user-facing gaming additions for the core
  workflow

Commit target:
- `feat(gaming): restore minimal steam-first stack`

### Phase 2: Reapply Only the Proven Compatibility Path

Targets:
- `modules/features/desktop/gaming.nix`

Changes:
- restore only the Steam-specific compatibility that already had a narrow owner
  and a concrete reason:
  - Steam-only IM bridge (`GTK_IM_MODULE`, `SDL_IM_MODULE`, `XMODIFIERS`) if
    current runtime proof still requires it
  - `programs.steam.extraPackages = [ pkgs.fcitx5-gtk ]` if Steam still needs
    the GTK module inside its runtime
  - `boot.kernelModules = [ "ntsync" ]` and `PROTON_USE_NTSYNC=1` only if the
    current kernel/runtime path still supports it cleanly
- keep `fcitx5` ownership in `modules/features/desktop/fcitx5.nix`
- keep GTK fallback ownership in `modules/features/desktop/theme-base.nix`

Validation:
- `./scripts/run-validation-gates.sh`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`
- fresh `predator` session
- verify text input in Steam login/search/chat fields
- inspect Steam process environment via `/proc/<pid>/environ` if input still
  fails

Diff expectation:
- Steam gets only the compatibility bridge it still demonstrably needs
- non-Steam desktop apps do not receive new global legacy exports

Commit target:
- `fix(gaming): restore steam compatibility path`

### Phase 3: Add the NVIDIA/Proton Performance Layer Carefully

Targets:
- `modules/features/desktop/gaming.nix`
- optionally `hardware/predator/hardware/gpu-nvidia.nix` only if a new
  hardware-owned delta is justified

Changes:
- start from the current already-kept NVIDIA baseline and add only measured,
  game-relevant Steam/Proton environment on top
- first candidates:
  - `PROTON_ENABLE_NVAPI=1`
  - `PROTON_ENABLE_NGX_UPDATER=1`
- explicitly do **not** restore `VKD3D_CONFIG=no_upload_hvv` as a host-wide
  default in the first performance slice; it was justified for an 8GB NVIDIA
  + ReBAR + Cyberpunk path, not yet for the generic "simple games" baseline
- explicitly do **not** revisit:
  - `cpuFreqGovernor = "performance"`
  - alternative swappiness values
  - broad memory-policy churn already rejected by the benchmark log

Validation:
- `./scripts/run-validation-gates.sh`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`
- `nix store diff-closures /run/current-system ./result` or equivalent
- real runtime check on `predator` with at least:
  - one lighter Proton title
  - one lighter native/Vulkan title if available
  - MangoHud or equivalent FPS/frametime observation

Diff expectation:
- small, explainable system diff centered on the Steam/Proton path
- no unrelated movement in host-global performance policy

Commit target:
- `feat(predator): add measured proton-nvidia performance path`

### Phase 4: Optional Tooling Layer After Core Stability

Targets:
- `modules/features/desktop/gaming.nix`

Changes:
- only after the Steam-first path is stable, choose which optional tools still
  earn their place:
  - `heroic`
  - `lutris`
  - `protonplus`
  - `goverlay`
  - `steam-run`
  - `steam-tui`
- add them intentionally instead of restoring the entire old bundle by default
- if a tool is not needed for the new "simple games on Linux" objective, leave
  it out

Validation:
- `./scripts/run-validation-gates.sh`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.<user>.home.path`
- verify the chosen tools actually launch

Diff expectation:
- HM closure grows by a clearly justified optional tool set only

Commit target:
- `feat(gaming): restore optional launcher/tooling layer`

### Phase 5: Runtime Proof and Supported Workflow Doc

Targets:
- active plan / follow-up docs if needed

Changes:
- record the final supported workflow for `predator`:
  - what is installed by default
  - which Steam launch options are recommended
  - which env vars are global vs Steam-only
  - which heavy-game workarounds remain explicitly per-game
- capture rollback notes in the same doc trail

Validation:
- `./scripts/run-validation-gates.sh`
- `./scripts/check-docs-drift.sh`
- fresh login + Steam launch + at least one verified game launch path

Diff expectation:
- docs and minor polish only

Commit target:
- `docs(gaming): record supported predator gaming workflow`

## Risks

- The old gaming stack was removed mostly for scope cleanup, but reintroducing
  it wholesale would also reintroduce too much surface area too early.
- Gamescope on NVIDIA/Wayland/Niri may still be useful later, but making it
  mandatory in the first slice would make regression isolation harder.
- Steam/Proton env vars can help one title and hurt another; broad defaults need
  runtime proof on this actual laptop.
- Cyberpunk-specific lessons are real, but they are the wrong baseline for the
  new goal. The repo should optimize for a good general Linux gaming path, not
  for solving every remaining Windows-vs-Linux gap.
- Validation gates are necessary but not sufficient; the final keep/reject call
  for gaming changes must come from real runtime verification on `predator`.

## Definition of Done

- `modules/features/desktop/gaming.nix` exists again and is wired explicitly
  into `modules/hosts/predator.nix`
- Steam is declaratively enabled on `predator`
- the restored baseline does not reintroduce previously rejected global tuning
  experiments
- Steam-specific compatibility stays narrow and auditable
- optional launchers/tools, if restored at all, are restored intentionally and
  separately from the core path
- the repo gates pass
- a real `predator` runtime check confirms the supported workflow for lighter
  Linux gaming without pretending the Windows-only performance gap has been
  solved
