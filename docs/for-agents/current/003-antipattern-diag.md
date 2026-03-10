# Antipattern Diagnostics

Date: 2026-03-09
Status: diagnostic only

Scope:
- repo-wide architectural review after the `core-options` refactor
- re-analysis against upstream den and dendritic patterns in `~/git/den` and `~/git/dendritic`

Reference patterns used for this review:
- dendritic README: every non-entry Nix file should name one feature and avoid ad-hoc pass-through architecture
- den core principles: feature-first organization and context-driven dispatch
- den HM/context docs and tests: host/user context should flow through den contexts, not through parallel local transport layers unless there is a clear reason

Resolved since the previous pass:
- `core-options.nix` as a schema dump is gone
- dead `host.descriptor` mirroring is gone
- Catppuccin no longer leaks from `home-manager-settings`
- validation host topology is no longer repeated in several unrelated scripts
- repo-local host-context transport is gone; host-aware features now use den parametric includes directly
- synthetic feature-presence booleans are gone
- shell ownership is den-owned via `user-shell`
- desktop/user `ConditionUser` filters are gone from tracked code
- canonical user account wiring now uses `define-user` + `primary-user`
- tracked feature/hardware consumers of `custom.user.name` are gone
- hostname ownership now comes from `den._.hostname` instead of `hardware/*/default.nix`

This file lists only confirmed live antipatterns.

## 1. The repo still carries a narrowed hybrid user bridge on top of den's user model

Why this is an antipattern:
- den already has host user schema plus `define-user`, `primary-user`, and `user-shell`
- this repo still models one compatibility username separately through `custom.user.name`
- the bridge is much narrower now, but it still creates a second user-identity control plane alongside den's native `{ host, user }` context

Evidence:
- `modules/features/user-context.nix#L1`
  declares `custom.user.name`
- `hardware/aurelius/private.nix.example#L1`
  still presents the bridge as the lower-level private override selector
- `scripts/check-config-contracts.sh#L50`
  still validates the bridge explicitly
- ~/git/den/modules/aspects/provides/define-user.nix#L1
  shows den already provides canonical OS/HM user definition from context

Impact:
- user identity is no longer split across tracked feature modules, but the compatibility path still exists
- private overrides still target the compatibility bridge instead of one den-native ownership path

## 2. `check-runtime-smoke.sh` is a deliberate tracked local-tool exception

Why this still deserves tracking:
- the script is honestly documented as predator-scoped
- it stays outside `run-validation-gates.sh`
- but it still lives as a top-level tracked tool under `scripts/`, so it remains
  a deliberate boundary exception instead of fully generic shared tooling

Evidence:
- `scripts/check-runtime-smoke.sh#L11`
  says it is a local predator desktop runtime smoke check
- `scripts/check-runtime-smoke.sh#L38`
  hardcodes `config_host="predator"`

Impact:
- the script is not generic shared tooling
- future desktop-host changes still require touching a special-case tracked script
- the repo intentionally carries one concrete host-local runtime tool in its shared script surface

## Notes

- The strongest remaining architectural findings are:
  1. narrowed hybrid compatibility bridge around `custom.user.name`
  2. deliberate tracked local-tool exception for runtime smoke
- The host metadata split is now deliberate:
  - `hardware/host-descriptors.nix` stays script-only for integrations metadata
  - `custom.host.role` remains the explicit runtime role contract
  - `den._.hostname` now owns hostnames
- The repo is still in a much better state than before the `core-options` refactor.
- These are now boundary and authority problems, not central-schema problems.
