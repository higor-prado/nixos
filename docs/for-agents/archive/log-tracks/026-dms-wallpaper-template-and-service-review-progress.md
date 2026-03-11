# DMS Wallpaper Template and Service Review Progress

## Status

Planned. Not executed yet.

## Scope

Targets:
- [dms-wallpaper.nix](../../../modules/features/desktop/dms-wallpaper.nix)
- new template under `config/apps/dms/`

## Baseline Already Known

Current runtime on `predator` before this refinement:
- `dms.service`: active
- `dms-awww.service`: active
- `awww-daemon.service`: active
- `~/.config/dms-awww/config.toml` exists and is valid

## Focus

1. Move TOML body out of the module into `config/` template form.
2. Review service density carefully and remove only clearly redundant wiring.
3. Preserve runtime behavior.

## Execution Notes

- Template extraction is the high-confidence cleanup.
- Service review baseline suggests the current density is mostly justified:
  - `awww-daemon.service` is small and straightforward.
  - `dms-awww.service` looks dense mostly because of runtime hardening and
    user-session integration, not because of accidental overengineering.
- Default expectation for this pass:
  - extract TOML template
  - keep service fields unchanged unless a field is clearly dead

## Execution Result

- Extracted `dms-awww/config.toml` body to:
  - [config/apps/dms/dms-awww-config.toml.in](../../../config/apps/dms/dms-awww-config.toml.in)
- Kept only `@DMS_SHELL_DIR@` interpolation in
  [dms-wallpaper.nix](../../../modules/features/desktop/dms-wallpaper.nix).
- Service review conclusion:
  - no further simplification was applied
  - remaining service density is justified by runtime and hardening needs

## Validation Result

- `./scripts/run-validation-gates.sh structure`: pass
- `./scripts/check-docs-drift.sh`: pass
- `bash scripts/check-changed-files-quality.sh`: pass
- `nix build` for `predator` system and HM: pass
- `nh os test path:$PWD`:
  - build phase passed
  - activation phase blocked only by `sudo` requiring a TTY in this execution environment
  - no config/version drift was reported before activation
