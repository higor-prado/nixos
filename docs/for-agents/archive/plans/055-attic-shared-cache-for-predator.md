# Attic Shared Cache for Predator

## Goal

Make the Attic instance hosted on `aurelius` useful for the normal `predator`
workflow by turning it into a shared binary cache: `aurelius` remains the
server, while both `aurelius` and `predator` can publish their own store paths
 automatically and `predator` can consume cached paths during normal Nix
operations.

## Scope

In scope:
- fix the Attic design so it matches the real objective instead of the partial
  "server only" state
- keep `aurelius` as the Attic server owner
- add an automatic producer path for `predator`
- preserve `predator` as an Attic consumer through private deployment facts
- prove the shared-cache workflow with a normal `predator` Nix operation
- update docs and the `050` roadmap to describe the real flow

Out of scope:
- backup/restic
- cache retention policy tuning
- cache garbage-collection strategy beyond what already exists
- non-`predator` clients
- public internet exposure outside the current Tailscale-only access model

## Current State

- The Attic runtime is now split into narrow owners:
  - [attic-server.nix](/home/higorprado/nixos/modules/features/system/attic-server.nix)
  - [attic-local-publisher.nix](/home/higorprado/nixos/modules/features/system/attic-local-publisher.nix)
  - [attic-publisher.nix](/home/higorprado/nixos/modules/features/system/attic-publisher.nix)
  - [attic-client.nix](/home/higorprado/nixos/modules/features/system/attic-client.nix)
- [modules/hosts/aurelius.nix](/home/higorprado/nixos/modules/hosts/aurelius.nix)
  composes `nixos.attic`
- [modules/hosts/predator.nix](/home/higorprado/nixos/modules/hosts/predator.nix)
  composes `nixos.attic-client`
- [private/hosts/predator/services.nix](/home/higorprado/nixos/private/hosts/predator/services.nix)
  already contains the real private consumer facts:
  - endpoint
  - public key
- The current producer path publishes only store paths that appear on
  `aurelius`.
- That means the current setup does not satisfy the real objective for
  `predator`, because normal `x86_64-linux` builds on `predator` do not feed the
  shared cache automatically.
- A real producer proof already exists on `aurelius`:
  - `attic-cache-bootstrap.service` succeeds
  - `attic-watch-store.service` is active
  - `journalctl -u attic-watch-store.service` shows successful uploads
- A real consumer proof already exists on `predator` for a known proof path:
  - `nix-store --realise ...` fetched from
    the configured private Attic substituter
- The missing piece is the producer path on `predator`.

## Desired End State

- `aurelius` remains the Attic server and shared cache host.
- `predator` automatically publishes its own new `x86_64-linux` store paths to
  the Attic cache during normal system usage.
- `predator` also consumes the same cache automatically through its normal Nix
  config.
- The tracked runtime does not hardcode deployment-specific endpoint or key
  facts in public files.
- Service semantics stay in Attic owners, not in host files.
- The final proof is a normal `predator` Nix operation that substitutes a path
  from the `aurelius` cache without any ad hoc manual `attic push`.

## Phases

### Phase 0: Baseline

Targets:
- [modules/features/system/attic-server.nix](/home/higorprado/nixos/modules/features/system/attic-server.nix)
- [modules/features/system/attic-local-publisher.nix](/home/higorprado/nixos/modules/features/system/attic-local-publisher.nix)
- [modules/features/system/attic-publisher.nix](/home/higorprado/nixos/modules/features/system/attic-publisher.nix)
- [modules/features/system/attic-client.nix](/home/higorprado/nixos/modules/features/system/attic-client.nix)
- [modules/hosts/aurelius.nix](/home/higorprado/nixos/modules/hosts/aurelius.nix)
- [modules/hosts/predator.nix](/home/higorprado/nixos/modules/hosts/predator.nix)
- [private/hosts/predator/services.nix](/home/higorprado/nixos/private/hosts/predator/services.nix)

Changes:
- freeze the exact current Attic responsibilities:
  - server on `aurelius`
  - local producer on `aurelius`
  - consumer on `predator`
- record the real missing requirement:
  - automatic producer on `predator`
- confirm whether any current Attic code mixes server-only concerns with
  producer concerns that should be split before adding `predator`

Validation:
- `./scripts/run-validation-gates.sh structure`
- `./scripts/check-repo-public-safety.sh`
- `ssh aurelius 'systemctl status attic-cache-bootstrap.service --no-pager -l'`
- `ssh aurelius 'systemctl status attic-watch-store.service --no-pager -l'`

Diff expectation:
- no runtime change or only planning/docs clarification

Commit target:
- `docs(attic): freeze shared-cache baseline`

### Phase 1: Split Attic Ownership Cleanly

Targets:
- [modules/features/system/attic-server.nix](/home/higorprado/nixos/modules/features/system/attic-server.nix)
- [modules/features/system/attic-local-publisher.nix](/home/higorprado/nixos/modules/features/system/attic-local-publisher.nix)
- [modules/features/system/attic-publisher.nix](/home/higorprado/nixos/modules/features/system/attic-publisher.nix)
- [modules/features/system/attic-client.nix](/home/higorprado/nixos/modules/features/system/attic-client.nix)

Changes:
- refactor the Attic owner so the concerns are explicit and reusable:
  - server concern
  - producer concern
  - consumer concern
- keep the server semantics in the server owner:
  - `services.atticd`
  - firewall opening on `tailscale0`
  - bootstrap of the cache that exists on the server host
- move the producer logic into a reusable narrow owner that can run on hosts
  other than the server
- keep deployment-specific producer facts narrow and private:
  - remote endpoint
  - cache name
  - token file or equivalent secret path
- do not push endpoint, cache key, or host/domain facts into public host owners

Validation:
- `./scripts/run-validation-gates.sh structure`
- `nix eval --raw path:$PWD#nixosConfigurations.aurelius.config.system.build.toplevel.drvPath`
- `nix eval --raw path:$PWD#nixosConfigurations.predator.config.system.build.toplevel.drvPath`

Diff expectation:
- Attic code becomes cleaner and more reusable without changing the intended
  visible behavior yet

Commit target:
- `refactor(attic): split server producer and consumer owners`

### Phase 2: Add Predator Automatic Producer

Targets:
- [modules/hosts/predator.nix](/home/higorprado/nixos/modules/hosts/predator.nix)
- [private/hosts/predator/services.nix](/home/higorprado/nixos/private/hosts/predator/services.nix)
- possibly [private/hosts/predator/services.nix.example](/home/higorprado/nixos/private/hosts/predator/services.nix.example)

Changes:
- compose the reusable Attic producer owner on `predator`
- keep host composition clean:
  - host only composes the published owner
  - no inline producer logic in the host file
- add only the private deployment facts required for `predator` to publish to
  the shared cache:
  - remote endpoint
  - cache name if required by the producer owner
  - token file or equivalent secret path
- ensure the producer path does not require ad hoc manual publish commands

Validation:
- `./scripts/run-validation-gates.sh structure`
- `nh os test path:$PWD`
- `systemctl status attic-watch-store.service --no-pager -l`
  on `predator` if the producer uses a watched systemd service
- otherwise the exact proving command for the producer mechanism introduced in
  this slice

Diff expectation:
- `predator` gains an automatic producer path without losing consumer behavior

Commit target:
- `feat(attic): add predator producer path`

### Phase 3: Prove Real Shared-Cache Workflow

Targets:
- no new owner by default; this is a proof slice

Changes:
- run a normal `predator` workflow that causes new `x86_64-linux` store paths
  to appear on `predator`
- confirm those paths are published automatically to the shared Attic cache
- then remove a chosen proof path locally on `predator` if safely possible, or
  use a follow-up normal Nix operation that must substitute it
- confirm the follow-up operation fetches from the configured private Attic
  substituter

Validation:
- `journalctl -u attic-watch-store.service` or equivalent producer proof on
  `predator`
- `journalctl -u attic-watch-store.service` or equivalent server-side proof on
  `aurelius` if useful
- a real `predator` Nix log showing:
  - `copying path ... from '<private-attic-substituter>'`
  - `substitution of path ... succeeded`

Diff expectation:
- no tracked runtime change or only tiny proof-only doc updates

Commit target:
- `docs(attic): record shared-cache proof`

### Phase 4: Tighten Docs and Roadmap

Targets:
- [docs/for-humans/04-private-overrides.md](/home/higorprado/nixos/docs/for-humans/04-private-overrides.md)
- [docs/for-humans/workflows/105-private-overrides.md](/home/higorprado/nixos/docs/for-humans/workflows/105-private-overrides.md)
- [docs/for-agents/plans/050-aurelius-next-steps-dendritic-plan.md](/home/higorprado/nixos/docs/for-agents/plans/050-aurelius-next-steps-dendritic-plan.md)
- [docs/for-agents/current/050-aurelius-next-steps-dendritic-plan-progress.md](/home/higorprado/nixos/docs/for-agents/current/050-aurelius-next-steps-dendritic-plan-progress.md)

Changes:
- document the real Attic model:
  - `aurelius` hosts the server
  - `predator` publishes and consumes through private deployment facts
  - the cache is useful in normal `predator` workflows because `predator`
    contributes its own outputs
- remove any wording that implies a server-only setup was already enough

Validation:
- `./scripts/check-docs-drift.sh`
- `./scripts/check-repo-public-safety.sh`

Diff expectation:
- documentation-only cleanup after the runtime proof exists

Commit target:
- `docs(attic): document shared predator workflow`

## Risks

- The Attic owner split may still reveal one more decomposition step is needed
  if the producer concerns diverge further in the future.
- The producer path on `predator` may need a private token file, which means
  final runtime proof depends on correct private override wiring.
- A proof that relies only on synthetic `attic push` must be rejected; the
  point is a normal `predator` workflow.
- If the producer mechanism on `predator` is not event-based, it may require a
  different proof strategy than the current `watch-store` journal on `aurelius`.

## Definition of Done

- `aurelius` hosts the Attic server through a narrow service owner.
- `predator` has a narrow automatic producer owner, composed cleanly from the
  host file.
- `predator` continues to consume the Attic cache through private deployment
  facts, not public tracked endpoint/key clutter.
- No Attic deployment semantics are spread across host owners.
- A normal `predator` Nix workflow causes new store paths to be published to
  the shared Attic cache automatically.
- A later normal `predator` Nix workflow substitutes at least one of those
  paths from the `aurelius` cache, with log proof.
- The roadmap and workflow docs describe exactly that real shared-cache model,
  not the weaker server-only state.
