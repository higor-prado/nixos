# Den Pattern Alignment Report

## Scope

- Compared this repo against local `den` at `4bdcb63` (`feat(batteries): Opt-in den._.bidirectional (#272)`) in `~/git/den`.
- Focused on current den context-shape guidance, host/user propagation patterns, and newer upstream style shown in templates/tests.

## Findings

### 1. `predator` still carries a user-scoped host include that does not appear to apply

Evidence in this repo:
- [modules/hosts/predator.nix](/home/higorprado/nixos/modules/hosts/predator.nix#L88) adds:
  - `({ user, ... }: { nixos.users.users.${user.userName}.extraGroups = [ "linuwu_sense" ]; })`
- Evaluated result on this machine:
  - `nix eval --json path:$PWD#nixosConfigurations.predator.config.users.users.higorprado.extraGroups`
  - result: `["wheel","networkmanager"]`
  - expected from the tracked intent/history would include `"linuwu_sense"`

Relevant den pattern:
- `den`'s current explicit user-scoped OS example uses `den.lib.parametric.exactly` for user-context-only config in `~/git/den/templates/ci/provider/modules/den.nix:39`.

Assessment:
- This is the only concrete repo/code mismatch I found.
- The tracked code reads as if `linuwu_sense` membership is still enforced from the host aspect, but the evaluated config does not show that membership.

Suggested direction:
- Move that membership to an explicit user-scoped helper/aspect using `den.lib.parametric.exactly`, or attach it from the user side with the same user-context semantics used by den's own examples/batteries.

### 2. Two living agent docs still teach a wider-than-necessary default context

Evidence in this repo:
- [000-operating-rules.md](/home/higorprado/nixos/docs/for-agents/000-operating-rules.md#L22) says tracked feature modules should prefer den `{ host, user }` context.
- [003-module-ownership.md](/home/higorprado/nixos/docs/for-agents/003-module-ownership.md#L31) says to prefer den `{ host, user }` context or user aspects.

Relevant den pattern:
- Current den guidance and your newer local docs now prefer the narrowest correct shape:
  - `{ host }` for host-aware config
  - owned `homeManager` when no host/user data is needed
  - `{ host, user }` only for genuinely user-specific logic

Assessment:
- This is a docs-guidance mismatch, not a runtime bug.
- It can still lead to future code drifting wider than current den expects.

Suggested direction:
- Update those two living docs so they say "prefer the narrowest correct den context shape" instead of generally preferring `{ host, user }`.

## Non-blocking Style Drift

### Repo still uses explicit `den.lib.parametric` wrappers almost everywhere

Relevant den pattern:
- Current den templates use plain aspect attrsets for many cases, for example `~/git/den/templates/default/modules/igloo.nix:3`.
- den also has explicit tests covering the newer auto-parametric/default-functor behavior in `~/git/den/templates/ci/modules/features/auto-parametric.nix:3`.

Assessment:
- This is not wrong and I did not find a failure caused by it.
- It is simply noisier than current upstream style and may make local code look older than it is.

Suggested direction:
- Treat this as gradual cleanup only. There is no need for a broad refactor unless you want the repo to track upstream style more closely.

## Intentional Divergences That Still Look Fine

- The repo still keeps `custom.user.name` as a compatibility bridge in [user-context.nix](/home/higorprado/nixos/modules/features/core/user-context.nix).
- That is a den divergence, but it is documented locally and I did not find misuse of it in tracked feature code beyond the bridge owner module itself.

## Bottom Line

- One actionable code mismatch: `predator`'s `linuwu_sense` membership wiring does not appear to be taking effect.
- One active-doc mismatch: two living docs still over-prefer `{ host, user }` instead of the narrowest context shape.
- Everything else I checked was either already aligned with current den or was only stylistic drift.
