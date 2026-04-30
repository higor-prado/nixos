# Fix bluetoothctl non-interactive mode (BlueZ 5.86)

## Goal

Restore Walker/Elephant Bluetooth provider output by patching the local BlueZ 5.86 package to fix the upstream regression where `bluetoothctl` in non-interactive mode (argv) produces no stdout.

## Scope

In scope:
- Patch `bluez` 5.86 with upstream fix for non-interactive stdout
- Validate `bluetoothctl show` and `bluetoothctl devices Paired` produce output
- Validate Elephant Bluetooth provider returns paired devices in Walker
- Update `modules/features/system/bluetooth.nix` with the overlay

Out of scope:
- Changing Elephant source code or provider logic
- Updating nixpkgs revision (surgical overlay is preferred)
- Bluetooth hardware/daemon troubleshooting (already confirmed working)

## Current State

- BlueZ version: 5.86
- Nixpkgs rev: `b12141ef619e0a9c1c84dc8c684040326f27cdcc`
- `bluetoothctl show` and `bluetoothctl devices Paired` return exit 0 with empty stdout
- Same commands via stdin pipe (`printf 'devices Paired\nquit\n' | bluetoothctl`) work correctly
- Elephant provider loads but returns `results=0` because it calls `bluetoothctl` via `exec.Command` in non-interactive mode
- BlueZ upstream issue: [#1896](https://github.com/bluez/bluez/issues/1896)
- Fix commit: [`34b31e0`](https://github.com/bluez/bluez/commit/34b31e091659601ec95a402c967e4eb565daeb2b)
- Local `bluez` package only has `static.patch`; does not include the non-interactive fix

## Desired End State

- `bluetoothctl show` prints controller info when run non-interactively
- `bluetoothctl devices Paired` prints paired devices when run non-interactively
- Walker shows Bluetooth devices via Elephant provider
- No workaround wrappers or PATH hacks needed

## Phases

### Phase 0: Baseline

Validation:
- Confirm current behavior:
  ```bash
  bluetoothctl show          # should be empty
  bluetoothctl devices Paired # should be empty
  printf 'devices Paired\nquit\n' | bluetoothctl  # should show 4 devices
  ```
- Confirm Elephant log shows `p=bluetooth results=0`
- Run validation gates: `./scripts/run-validation-gates.sh`
- Run `nix flake check`

### Phase 1: Apply BlueZ patch overlay

Targets:
- `modules/features/system/bluetooth.nix`

Changes:
- Add `nixpkgs.overlays` in `modules/features/system/bluetooth.nix` to patch `bluez`
- Fetch patch from `https://github.com/bluez/bluez/commit/34b31e091659601ec95a402c967e4eb565daeb2b.patch`
- Apply via `overrideAttrs` adding the patch to `patches`

Example shape:
```nix
{
  nixpkgs.overlays = [
    (final: prev: {
      bluez = prev.bluez.overrideAttrs (oldAttrs: {
        patches = oldAttrs.patches ++ [
          (final.fetchpatch {
            name = "fix-bt_shell_printf-noninteractive.patch";
            url = "https://github.com/bluez/bluez/commit/34b31e091659601ec95a402c967e4eb565daeb2b.patch";
            hash = "...";  # to be filled after first build attempt
          })
        ];
      });
    })
  ];
}
```

Validation:
- Build the system configuration: `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`
- Verify the new `bluez` derivation is different from the old one
- Check that the patch is listed in the derivation: `nix eval --json path:$PWD#nixosConfigurations.predator.pkgs.bluez.patches`

### Phase 2: Switch and runtime validation

Targets:
- Live system on `predator`

Changes:
- Switch to the new configuration

Validation:
- `bluetoothctl show` must print controller info (non-empty stdout)
- `bluetoothctl devices Paired` must print the 4 paired devices
- Elephant log must show `p=bluetooth results=4` (or non-zero) when querying via Walker
- Walker must display Bluetooth devices when provider is queried
- All validation gates pass
- `nix flake check` passes

Diff expectation:
- `modules/features/system/bluetooth.nix` gains `nixpkgs.overlays` block
- No other files changed

Commit target:
- `fix(system): patch bluez 5.86 to restore non-interactive bluetoothctl output`

## Risks

- Patch may not apply cleanly to the exact 5.86 tarball used by nixpkgs; if so, may need to fetch a different patch format or create a local patch file
- If the `34b31e0` patch does not apply cleanly, fallback to the upstream-merged revert (`b33e923`) + workaround (`21e1397`) combination
- Overlay affects all consumers of `bluez` in the system closure; risk is low because the patch is a 3-line logic fix in `bt_shell_printf`

## Definition of Done

- [ ] `bluetoothctl show` produces non-empty output when run non-interactively
- [ ] `bluetoothctl devices Paired` produces non-empty output when run non-interactively
- [ ] Elephant/Walker Bluetooth provider shows paired devices
- [ ] All validation gates pass for `predator`
- [ ] `nix flake check` passes
- [ ] Plan archived to `docs/for-agents/archive/plans/`

## References

- BlueZ issue: https://github.com/bluez/bluez/issues/1896
- Fix commit: https://github.com/bluez/bluez/commit/34b31e091659601ec95a402c967e4eb565daeb2b
- Elephant bluetooth provider source: https://github.com/abenz1267/elephant/blob/master/internal/providers/bluetooth/setup.go
- Local `bluetooth.nix`: `modules/features/system/bluetooth.nix`
- Local `bluez` package: `/nix/store/qr55dhy8mnfhm4r07638bfg5cdxrg4qc-l61vfkyy0qrnz9bmgx84fa7z3bjzhyp4-source/pkgs/by-name/bl/bluez/package.nix`
