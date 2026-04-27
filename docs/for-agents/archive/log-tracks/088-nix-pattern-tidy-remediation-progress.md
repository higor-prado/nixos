# Nix Pattern Tidy Remediation Progress

## Status

In progress

## Related Plan

- [088-nix-pattern-tidy-remediation.md](/home/higorprado/nixos/docs/for-agents/plans/088-nix-pattern-tidy-remediation.md)

## Baseline

- Branch: `cleanup/hyprland-only`
- Plan committed: `592d10f docs(agents): plan nix pattern tidy remediation`
- Working tree clean before execution.
- Baseline checks:
  - `./scripts/check-docs-drift.sh` ✅
  - `./scripts/run-validation-gates.sh structure` ✅

## Slices

### Slice 1 — Theme source of truth and helper split

- Changes:
  - `modules/features/desktop/theme-zen.nix` now reads flavor/accent from `modules/features/desktop/_theme-catalog.nix`.
  - moved the tray icon patch derivation out of `_theme-catalog.nix` into new feature-private helper `modules/features/desktop/_papirus-tray-patched.nix`.
  - `_theme-catalog.nix` now references the helper and remains a theme catalog owner.
- Validation:
  - `./scripts/check-docs-drift.sh`
  - `./scripts/run-validation-gates.sh structure`
  - `nix run --no-write-lock-file nixpkgs#deadnix -- --fail modules/features modules/desktops`
- Commit:
  - `5ae13ea refactor(theme): consume catalog and split tray icon helper`

### Slice 2 — Predator package-set derivation cleanup

- Changes:
  - removed extra `inputs.nixpkgs` package-set instantiation from `modules/hosts/predator.nix`.
  - `customPkgs` is now derived from the evaluated HM `pkgs` inside the user module lambda.
- Validation:
  - `./scripts/run-validation-gates.sh all`
- Commit:
  - `d0a29e2 refactor(hosts): derive predator custom packages from pkgs`

### Slice 3 — Aurelius-specific owner naming

- Changes:
  - renamed modules/files and published names to match their concrete host-specific ownership:
    - `modules/features/system/aurelius-attic-server.nix`
    - `modules/features/system/aurelius-attic-local-publisher.nix`
    - `modules/features/system/aurelius-github-runner.nix`
  - updated `modules/hosts/aurelius.nix` imports to the renamed module publishers.
- Validation:
  - `./scripts/check-feature-publisher-name-match.sh`
  - `./scripts/run-validation-gates.sh all`
- Commit:
  - `4bbec98 refactor(system): name aurelius-specific service owners`

### Slice 4 — Contract clarifications for constrained exceptions

- Changes:
  - documented Cerebelo RK3588 `_module.args` bridge rationale in `modules/hosts/cerebelo.nix`.
  - documented intentional Spicetify ownership/import in `modules/features/desktop/music-client.nix`.
  - documented single-owner Tailscale Serve contract in `modules/features/media/aiostreams.nix`.
- Validation:
  - `./scripts/run-validation-gates.sh all`
- Commit:
  - `8b6b9e2 docs(nix): clarify host-specific owner contracts`

### Slice 5 — Low-risk lint noise reduction

- Changes:
  - removed unused lambda args and low-risk lint noise in:
    - `modules/features/desktop/fcitx5.nix`
    - `modules/features/desktop/waypaper.nix`
    - `modules/features/system/docker.nix`
    - `modules/features/system/maintenance.nix`
    - `modules/features/system/networking-wireguard-client.nix`
    - `modules/features/system/networking-resolved.nix`
- Validation:
  - `nix run --no-write-lock-file nixpkgs#deadnix -- --fail modules/features modules/desktops`
  - `./scripts/run-validation-gates.sh all`
- Commit:
  - `08b276d chore(nix): remove low-risk feature lint noise`

### Slice 6 — Living docs sync for new owners/helpers

- Changes:
  - updated `docs/for-agents/001-repo-map.md` for:
    - new feature-private helper `_papirus-tray-patched.nix`
    - theme-zen consumption of `_theme-catalog.nix`
    - Aurelius-specific owner filenames
  - updated active plan target paths in `docs/for-agents/plans/088-nix-pattern-tidy-remediation.md` after renames.
- Validation:
  - `./scripts/check-docs-drift.sh`
  - `./scripts/run-validation-gates.sh structure`

## Final State

- The plan goals were executed with small, validated commits.
- Theme source duplication in `theme-zen.nix` was removed.
- The theme catalog no longer embeds the long tray patch derivation script.
- Predator no longer instantiates an extra `nixpkgs` set for local packages.
- Aurelius-specific owners now have explicit Aurelius-specific names.
- Cerebelo `_module.args` remains as an explicitly documented upstream compatibility bridge.
- Music-client and AIOStreams ownership contracts are documented in-owner.
- Deadnix actionable warnings for the targeted feature surfaces were removed.
- Validation:
  - `./scripts/check-docs-drift.sh` ✅
  - `./scripts/run-validation-gates.sh structure` ✅
  - `./scripts/run-validation-gates.sh all` ✅
  - `./scripts/check-repo-public-safety.sh` ✅
