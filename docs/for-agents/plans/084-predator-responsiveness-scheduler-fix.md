# Predator responsiveness fix under load (scheduler inheritance)

## Goal

Eliminate UI/input freezes during heavy background workloads by fixing scheduler/class inheritance in the Predator login/session tree, so compositor and interactive apps keep responsive CPU scheduling while builds run.

## Scope

In scope:
- Fix ananicy behavior that pushes session-root processes into `SCHED_IDLE`
- Ensure ananicy config changes are actually applied on switch
- Add targeted rule overrides for login/session bootstrap processes (`greetd`, `regreet`, `start-hyprland`)
- Provide an objective stress harness to validate responsiveness under load

Out of scope:
- Replacing Hyprland/Niri
- Replacing dbus-broker
- GPU driver tuning changes

## Current State

- Runtime evidence shows `greetd` and `Hyprland` running as `SCHED_IDLE`.
- This is consistent with ananicy CachyOS defaults: `greetd`/`regreet` are `BG_CPUIO` and `BG_CPUIO` includes `sched=idle`.
- Even after setting `services.ananicy.settings.apply_sched = false`, the running daemon may not reload/restart automatically after switch, so stale policy can persist.
- Portal/file-picker issues are tracked separately in plan 083.

## Desired End State

- `greetd --session-worker` and `Hyprland` run with `SCHED_OTHER` (not `SCHED_IDLE`).
- Interactive apps (Zed/Firefox) remain responsive while high CPU/IO stress runs.
- ananicy changes become reliably applied on switch without manual guessing.

## Phases

### Phase 0: Baseline confirmation

Validation:
- `pgrep -a greetd`
- `chrt -p $(pgrep -xo greetd)`
- `chrt -p $(pgrep -xo Hyprland)`
- capture whether policy is `SCHED_IDLE`

### Phase 1: Declarative scheduler policy hardening

Targets:
- `hardware/predator/performance.nix`

Changes:
- Keep `services.ananicy.settings.apply_sched = false`.
- Add rule overrides in `services.ananicy.extraRules`:
  - `greetd` -> `Service`
  - `regreet` -> `Service`
  - `start-hyprland` -> `LowLatency_RT`
  - keep existing `keyrs` override
- Ensure switch applies daemon config by adding restart trigger:
  - `systemd.services.ananicy-cpp.restartTriggers = [ config.environment.etc."ananicy.d".source ];`

Validation:
- `nix eval --json path:$PWD#nixosConfigurations.predator.config.services.ananicy.settings.apply_sched`
- `nix eval --json path:$PWD#nixosConfigurations.predator.config.systemd.services.ananicy-cpp.restartTriggers`
- `./scripts/run-validation-gates.sh structure`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`

Diff expectation:
- ananicy config becomes robust against scheduler-idle leaks from login manager tree.

Commit target:
- `fix(performance): prevent session scheduler-idle inheritance on predator`

### Phase 2: Runtime validation after switch + greetd restart (or reboot)

Targets:
- runtime only

Changes:
- apply new generation (`nh os switch`)
- restart display manager path (`systemctl restart greetd` or reboot)

Validation:
- `chrt -p $(pgrep -xo greetd)` -> `SCHED_OTHER`
- `chrt -p $(pgrep -xo Hyprland)` -> `SCHED_OTHER`
- `ananicy-cpp dump proc` for `greetd`/`Hyprland` shows `sched: normal`

### Phase 3: High-load responsiveness acceptance test

Targets:
- runtime only

Changes:
- run heavy secondary load in low-priority systemd scope:
  ```bash
  systemd-run --user --unit=bg-stress --collect \
    -p Nice=19 -p IOSchedulingClass=idle -p IOSchedulingPriority=7 -p CPUWeight=1 \
    bash -lc 'nix run nixpkgs#stress-ng -- --cpu $(nproc) --io 4 --vm 2 --vm-bytes 60% --timeout 180s --metrics-brief'
  ```

Validation:
- During stress:
  - type continuously in Zed
  - type in WhatsApp Web (Firefox)
  - open file picker in Zed
- Success criteria: no sustained input freeze (>500ms perceived lockup)

## Risks

- If user manager / greetd is not restarted after switch, old scheduling state can survive.
- ananicy rule precedence depends on load order; `nixRules.rules` must continue to override defaults.

## Definition of Done

- `greetd` and `Hyprland` no longer run as `SCHED_IDLE` after applying generation and restarting login path.
- Stress harness runs for 180s without reproducible input freeze in Zed/Firefox.
- Structure and build validation pass.
