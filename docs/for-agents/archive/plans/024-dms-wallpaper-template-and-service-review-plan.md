# DMS Wallpaper Template and Service Review Plan

## Goal

Finish the cleanup of [dms-wallpaper.nix](../../../modules/features/desktop/dms-wallpaper.nix) by:

1. moving the static body of `dms-awww/config.toml` into `config/` as a template,
2. keeping only the dynamic interpolation in the module,
3. reviewing the `awww-daemon` and `dms-awww` services to identify whether any current wiring is genuine runtime need or unnecessary complexity.

This is a refinement pass after the earlier cleanup:
- `config.toml` already became declarative via `xdg.configFile`
- package ownership was simplified toward HM ownership

## Non-Goals

- changing the functional role of `dms-awww`
- splitting wallpaper and theme integration apart
- redesigning `dms-awww`
- changing the semantics of `dms-awww.service`
- changing DMS ownership again

## Why This Pass Exists

The current module is better than before, but two issues remain:

1. `config.toml` is still inline in the Nix module.
   - this is harder to read than a template in `config/`

2. the service definitions may still feel dense.
   - not all density is bad
   - this pass should distinguish:
     - required runtime hardening / dependency declarations
     - truly unnecessary wiring

## Current Service Review Hypothesis

Preliminary judgment before execution:

### `awww-daemon.service`
Likely justified:
- `After = graphical-session.target`
- `PartOf = graphical-session.target`
- `Restart = on-failure`
- explicit `HOME` and `XDG_RUNTIME_DIR`

Likely low-risk to keep:
- `StandardOutput = journal`
- `StandardError = journal`

This service does **not** currently look overengineered.

### `dms-awww.service`
Likely justified:
- `After` / `Requires` on `awww-daemon.service`
- `ConditionPathExists` for user config
- `EnvironmentFile = -%h/.config/dms-awww/environment`
- hardening:
  - `NoNewPrivileges`
  - `PrivateTmp`
  - `ProtectSystem = strict`
  - `ProtectHome = read-only`
  - `ReadWritePaths`

This service likely looks dense because it has to balance:
- user config access
- DMS cache/config writes
- systemd hardening
- runtime env for Wayland/DBus

So the default assumption should be:
- keep the service as-is unless a field is clearly redundant

## Execution Phases

### Phase 0: Baseline

Capture current state:

```bash
systemctl --user status dms.service --no-pager
systemctl --user status dms-awww.service --no-pager
systemctl --user status awww-daemon.service --no-pager
sed -n '1,120p' ~/.config/dms-awww/config.toml
nix build .#nixosConfigurations.predator.config.system.build.toplevel -o /tmp/dms-wallpaper-template-before-system
nix build .#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path -o /tmp/dms-wallpaper-template-before-hm
```

### Phase 1: Move TOML Body to a Template File

Create:
- [config/apps/dms/dms-awww-config.toml.in](../../../config/apps/dms/dms-awww-config.toml.in)

Template format:
- keep the file almost fully static
- use a narrow placeholder only for the dynamic value:
  - `@DMS_SHELL_DIR@`

Module change:
- replace inline TOML text with:
  - `builtins.readFile` of the template
  - `lib.replaceStrings [ "@DMS_SHELL_DIR@" ] [ "${dmsPackage}/share/quickshell/dms" ]`

Validation:

```bash
./scripts/run-validation-gates.sh structure
nix build .#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path -o /tmp/dms-wallpaper-template-phase1-hm
nix store diff-closures /tmp/dms-wallpaper-template-before-hm /tmp/dms-wallpaper-template-phase1-hm
```

Expected:
- only mechanical HM changes, ideally none beyond template derivation movement

Commit target:
- `refactor: template dms-awww config`

### Phase 2: Service Review

Review each field in both services and classify it as:
- `required`
- `helpful but optional`
- `dead`

Only remove fields if all 3 are true:
1. there is a clear technical reason they are redundant,
2. evaluated service output still stays correct,
3. runtime test stays clean after `nh os test`

Likely default result:
- keep most of the service definition intact
- maybe only reduce obvious noise if found

Validation:

```bash
./scripts/run-validation-gates.sh structure
./scripts/run-validation-gates.sh predator
nix build .#nixosConfigurations.predator.config.system.build.toplevel -o /tmp/dms-wallpaper-template-phase2-system
nix build .#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path -o /tmp/dms-wallpaper-template-phase2-hm
nix store diff-closures /tmp/dms-wallpaper-template-before-system /tmp/dms-wallpaper-template-phase2-system
nix store diff-closures /tmp/dms-wallpaper-template-phase1-hm /tmp/dms-wallpaper-template-phase2-hm
```

Runtime check:

```bash
nh os test path:$PWD
systemctl --user status dms.service --no-pager
systemctl --user status dms-awww.service --no-pager
systemctl --user status awww-daemon.service --no-pager
sed -n '1,120p' ~/.config/dms-awww/config.toml
```

Commit target:
- `refactor: review dms wallpaper service wiring`

### Phase 3: Docs and Closeout

Update:
- [023-dms-wallpaper-wiring-cleanup-plan.md](023-dms-wallpaper-wiring-cleanup-plan.md) only if needed
- [025-dms-wallpaper-wiring-cleanup-progress.md](../current/025-dms-wallpaper-wiring-cleanup-progress.md)
- add a new closeout log if this refinement is substantial enough

Validation:

```bash
./scripts/check-docs-drift.sh
bash scripts/check-changed-files-quality.sh
./scripts/check-repo-public-safety.sh
```

## Success Criteria

- `dms-awww/config.toml` body lives in `config/`
- only the dynamic `shell_dir` remains interpolated in Nix
- services are either simplified safely or explicitly retained as necessary complexity
- no regression in:
  - `dms.service`
  - `dms-awww.service`
  - `awww-daemon.service`

## Notes for the Agent

- Do not remove service hardening or runtime env fields just for brevity.
- This pass is successful even if the conclusion is:
  - “services look dense, but the density is justified”
- The main guaranteed win is the TOML template extraction.
