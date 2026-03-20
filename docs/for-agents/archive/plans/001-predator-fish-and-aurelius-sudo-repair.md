# Predator Fish Abbrs and Aurelius Sudo Repair

## Goal

Restore two regressions introduced during the Den removal work: the missing
Predator NixOS/Fish operator abbreviations and the lost admin/sudo semantics for
the tracked primary user. The fix should follow the current dendritic runtime,
keep ownership narrow, and avoid reintroducing option wrappers or Den-era
indirection.

## Scope

In scope:
- restore the missing `npu*` / `nau*` Fish abbreviations on `predator`
- restore the intended admin/sudo semantics for `higorprado`
- validate both hosts after the repair
- update living docs if the repaired ownership model needs clarification

Out of scope:
- redesigning the full user model
- removing `custom.user.name`
- changing private override behavior beyond what is needed to regain parity
- unrelated Fish or sudo policy cleanup

## Current State

- `predator` no longer declares the operator abbreviations that used to live in
  the old Den-era `provides.higorprado.homeManager` block.
- `aurelius` still declares the smaller `nau*` abbreviations directly in host
  composition, but `predator` does not.
- current Home eval for `predator` confirms that `npu*` / `nau*` are absent from
  `home-manager.users.higorprado.programs.fish.shellAbbrs`.
- current user eval for both `predator` and `aurelius` shows that
  `users.users.higorprado.extraGroups` does not include `wheel`.
- `modules/users/higorprado.nix` currently defines the tracked primary user but
  does not encode the old `den._.primary-user` admin semantics.
- `security.sudo` is still enabled, and `aurelius` currently relies on narrow
  extra sudo rules rather than the normal tracked admin path.

## Desired End State

- `predator` HM eval includes the intended `npu*` / `nau*` Fish abbreviations.
- tracked admin semantics are explicit in the repo-local runtime instead of
  being accidental leftovers from Den.
- `higorprado` regains the correct sudo/admin capability on the intended hosts.
- no new `mkOption` wrappers or helper framework layers are introduced.
- ownership remains local and obvious from the runtime topology.

## Phases

### Phase 0: Baseline

Validation:
- `nix eval --json path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.programs.fish.shellAbbrs`
- `nix eval --json path:$PWD#nixosConfigurations.predator.config.users.users.higorprado.extraGroups`
- `nix eval --json path:$PWD#nixosConfigurations.aurelius.config.users.users.higorprado.extraGroups`
- `nix eval --json path:$PWD#nixosConfigurations.aurelius.config.security.sudo`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`

### Phase 1: Restore Predator Operator Abbreviations

Targets:
- `modules/hosts/predator.nix`

Changes:
- reintroduce the host/operator Fish abbreviations in the `predator` owner
- keep them in host composition or a local host-owned HM binding, not in the
  shared `fish` feature and not behind a generic option surface
- preserve the current shared `fish` feature as generic/base behavior only

Validation:
- `nix eval --json path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.programs.fish.shellAbbrs`
- verify presence of `npu`, `npub`, `nput`, `npus`, `nau`, `naub`, `naut`,
  `naus`, `naui`, `nausi`, `naust`, `nauc`, `nauct`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`

Diff expectation:
- `predator` HM closure regains Fish config/abbr payload for operator commands

Commit target:
- `fix(predator): restore host operator fish abbreviations`

### Phase 2: Restore Primary User Admin Semantics

Targets:
- `modules/users/higorprado.nix`
- possibly `modules/hosts/aurelius.nix` only if host-specific narrowing is
  actually intended after baseline review

Changes:
- make the tracked primary-user admin path explicit in the repo-local runtime
- prefer expressing the old primary-user semantics in the user owner if the
  intent is cross-host admin access for the tracked primary user
- only use host-local augmentation if the baseline proves that admin rights are
  intentionally host-specific
- do not rely on private sudo rules as the sole tracked admin mechanism

Validation:
- `nix eval --json path:$PWD#nixosConfigurations.predator.config.users.users.higorprado.extraGroups`
- `nix eval --json path:$PWD#nixosConfigurations.aurelius.config.users.users.higorprado.extraGroups`
- `nix eval --json path:$PWD#nixosConfigurations.aurelius.config.security.sudo`
- verify the intended tracked admin group is present
- `nix build --no-link path:$PWD#nixosConfigurations.aurelius.config.system.build.toplevel`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`

Diff expectation:
- the tracked primary user regains explicit admin-group membership in eval
- sudo capability no longer depends solely on private extra rules

Commit target:
- `fix(users): restore primary user admin semantics`

### Phase 3: Docs and Final Validation

Targets:
- `docs/for-agents/002-architecture.md`
- `docs/for-agents/003-module-ownership.md`
- `docs/for-agents/999-lessons-learned.md`
- only if needed by the chosen ownership model

Changes:
- document the repaired ownership boundary if it changed materially
- keep the explanation narrow: host operator Fish commands live with host
  composition; tracked admin semantics live with the user model unless proven
  host-specific

Validation:
- `./scripts/check-docs-drift.sh`
- `./scripts/run-validation-gates.sh`
- `bash tests/scripts/gate-cli-contracts-test.sh`
- `nix store diff-closures <old-system> <new-system>` for the affected host if
  the repair changes evaluated system payload materially

Diff expectation:
- no structural regressions
- only the intended Fish/admin surfaces change

Commit target:
- `docs(runtime): clarify host operator fish and admin ownership`

## Risks

- adding `wheel` in the wrong owner could over-broaden admin rights if the repo
  actually wants host-specific admin membership
- restoring the abbreviations in the shared `fish` feature would pollute the
  global shell surface and repeat the old mistake
- private overrides may currently assume the narrowed compatibility bridge, so
  the tracked fix must preserve that boundary

## Definition of Done

- `predator` has the intended operator Fish abbreviations again
- `higorprado` regains explicit tracked admin semantics on the intended hosts
- the chosen ownership is consistent with the dendritic pattern
- validation gates and targeted eval/build checks pass
