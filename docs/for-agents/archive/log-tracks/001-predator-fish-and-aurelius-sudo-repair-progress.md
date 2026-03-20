# Predator Fish and Aurelius Sudo Repair Progress

## Status

Completed

## Related Plan

- [001-predator-fish-and-aurelius-sudo-repair.md](/home/higorprado/nixos/docs/for-agents/plans/001-predator-fish-and-aurelius-sudo-repair.md)

## Baseline

- `predator` HM Fish abbreviations did not include `npu*` or `nau*`.
- `aurelius` and `predator` both evaluated `users.users.higorprado.extraGroups` to:
  - `["video","audio","input","docker","rfkill","uinput","linuwu_sense"]`
- baseline `predator` HM closure:
  - `/nix/store/6w9j484abrfb4w648y1zx4vjzk4wacbp-home-manager-path`
- baseline `predator` system closure:
  - `/nix/store/5mizkll54ls90djj6jjh43pcizsbh4kn-nixos-system-predator-26.05.20260318.b40629e`
- Den source confirmation:
  - `den.provides.primary-user` used to add `wheel` and `networkmanager`

## Slices

### Slice 1

- Baseline captured; no repo changes yet.
- Verified that Predator lost the host operator Fish abbreviations during the
  Den runtime removal.
- Verified that the repo-local user owner no longer re-expresses the old
  `primary-user` admin semantics.

Validation:
- `nix eval --json path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.programs.fish.shellAbbrs`
- `nix eval --json path:$PWD#nixosConfigurations.aurelius.config.users.users.higorprado.extraGroups`
- `nix build --no-link --print-out-paths path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`
- `nix build --no-link --print-out-paths path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`

Diff result:
- baseline only

Commit:
- none

### Slice 2

- Restored the missing Predator operator abbreviations directly in
  `modules/hosts/predator.nix` as host-owned HM wiring.
- Kept the shared `fish` feature generic; no host-specific option surface was
  reintroduced.

Validation:
- `nix eval --json path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.programs.fish.shellAbbrs`
- confirmed `npu*` and `nau*` are present again
- `nix build --no-link --print-out-paths path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`

Diff result:
- Predator HM eval regained the expected operator aliases

Commit:
- planned as focused fix commit

### Slice 3

- Restored explicit primary-user admin semantics in
  `modules/users/higorprado.nix`.
- Reintroduced `wheel` and `networkmanager` through the user owner instead of
  relying on host-local sudo exceptions.
- Updated living docs to make the ownership boundary explicit.

Validation:
- `nix eval --json path:$PWD#nixosConfigurations.predator.config.users.users.higorprado.extraGroups`
- `nix eval --json path:$PWD#nixosConfigurations.aurelius.config.users.users.higorprado.extraGroups`
- `./scripts/run-validation-gates.sh all`
- `nix store diff-closures /nix/store/5mizkll54ls90djj6jjh43pcizsbh4kn-nixos-system-predator-26.05.20260318.b40629e /nix/store/5vznijmk63pkwy1wh952a468jb8ycs42-nixos-system-predator-26.05.20260318.b40629e`

Diff result:
- both hosts regained explicit tracked admin groups
- Predator system closure changed only in config payload; `diff-closures`
  produced no package-level additions/removals

Commit:
- planned as focused fix/docs commits

## Final State

- `predator` again exposes the expected `npu*` / `nau*` Fish abbreviations.
- `higorprado` again evaluates with `wheel` and `networkmanager` on both
  tracked hosts.
- Living docs now state that host-operator shell commands belong in host
  composition and repo-wide primary-user semantics belong in the user owner.
