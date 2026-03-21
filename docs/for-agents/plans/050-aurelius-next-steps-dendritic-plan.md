# Aurelius Next Steps Dendritic Plan

## Goal

Turn `aurelius` into a repo-native server and remote-development host using the
existing dendritic runtime of this repo, while translating the generic roadmap
in `docs/for-agents/current/reference.md` into explicit host composition,
narrow feature owners, and declarative service ownership. Backups are
intentionally excluded for now.

## Scope

In scope:
- reframe the temporary roadmap in `docs/for-agents/current/reference.md`
- plan `aurelius` foundation changes for Docker, remote dev, and service hosting
- plan Attic, Forgejo, observability, GitHub runner, and Tailscale/exit-node work
- define where new runtime should live: host file, feature owner, hardware, or
  private override
- define validation and commit boundaries for each slice
- call out generic recommendations from the temporary roadmap that should not be
  implemented as-is in this repo

Out of scope:
- backup/restic work for `aurelius`
- Orange Pi migration and future storage-node work
- `vpn-us` / GCP provisioning
- implementing the roadmap in this turn
- cleaning the pre-existing worktree noise around archived plan files `048` and
  `049`

## Current State

- The tracked host owner is [modules/hosts/aurelius.nix](/home/higorprado/nixos/modules/hosts/aurelius.nix).
- The current `aurelius` NixOS baseline already includes:
  - `nixos.system-base`
  - `nixos.home-manager-settings`
  - `nixos.networking`
  - `nixos.security`
  - `nixos.keyboard`
  - `nixos.nixpkgs-settings`
  - `nixos.maintenance`
  - `nixos.tailscale`
  - `nixos.higorprado`
  - `nixos.nix-settings`
  - `nixos.packages-server-tools`
  - `nixos.packages-system-tools`
  - `nixos.fish`
  - `nixos.ssh`
- The current Home Manager baseline for `aurelius` already includes:
  - `homeManager.higorprado`
  - `homeManager.core-user-packages`
  - `homeManager.fish`
  - `homeManager.git-gh`
  - `homeManager.ssh`
- The hardware boundary for `aurelius` is already in place:
  - [hardware/aurelius/default.nix](/home/higorprado/nixos/hardware/aurelius/default.nix)
  - [hardware/aurelius/disko.nix](/home/higorprado/nixos/hardware/aurelius/disko.nix)
  - [hardware/aurelius/hardware-configuration.nix](/home/higorprado/nixos/hardware/aurelius/hardware-configuration.nix)
  - [hardware/aurelius/performance.nix](/home/higorprado/nixos/hardware/aurelius/performance.nix)
- Several features proposed by the temporary roadmap already exist and should
  be reused instead of reinvented:
  - [modules/features/system/docker.nix](/home/higorprado/nixos/modules/features/system/docker.nix)
  - [modules/features/dev/editor-neovim.nix](/home/higorprado/nixos/modules/features/dev/editor-neovim.nix)
  - [modules/features/dev/packages-toolchains.nix](/home/higorprado/nixos/modules/features/dev/packages-toolchains.nix)
  - [modules/features/dev/dev-tools.nix](/home/higorprado/nixos/modules/features/dev/dev-tools.nix)
  - [modules/features/dev/dev-devenv.nix](/home/higorprado/nixos/modules/features/dev/dev-devenv.nix)
  - [modules/features/shell/terminal-tmux.nix](/home/higorprado/nixos/modules/features/shell/terminal-tmux.nix)
  - [modules/features/shell/tui-tools.nix](/home/higorprado/nixos/modules/features/shell/tui-tools.nix)
  - [modules/features/shell/starship.nix](/home/higorprado/nixos/modules/features/shell/starship.nix)
  - [modules/features/shell/monitoring-tools.nix](/home/higorprado/nixos/modules/features/shell/monitoring-tools.nix)
- The temporary roadmap is useful as an idea dump, but it does not follow repo
  policy closely enough. Its main problems are:
  - it treats `docker-compose.yml` plus `~/services/*` as the default tracked
    service shape
  - it proposes home-directory `mkdir` steps for service state instead of
    declarative service-owned state directories
  - it introduces a broad `aurelius-automation.nix` bucket
  - it mixes real tracked runtime work with operator-only manual steps
  - it ends with generic validation (`nix flake check`) instead of the repo's
    canonical validation gates
- The current repo rules require:
  - explicit host composition in `modules/hosts/*.nix`
  - reusable behavior in narrow `modules/features/**` owners
  - hardware-specific state in `hardware/<name>/`
  - no new generic runtime carrier or helper framework

## Desired End State

- The active roadmap for `aurelius` is expressed in repo-native terms rather
  than generic ad hoc snippets.
- Each new concern has a clear owner:
  - host composition in `modules/hosts/aurelius.nix`
  - reusable service behavior in narrow `modules/features/system/*.nix`
  - machine tuning in `hardware/aurelius/*`
  - secrets and tokens in private overrides, not tracked files
- No active plan instructs the repo to rely on `docker-compose.yml` under the
  user's home directory as the canonical tracked service model.
- No active plan introduces a generic automation bucket when service-owned
  timers/maintenance would be clearer.
- The roadmap is ordered by real dependency and value:
  1. foundation
  2. remote development
  3. service stack
  4. access/exposure
  5. service-owned maintenance
- Backup is explicitly deferred and does not leak into the implementation plan.

## Phases

### Phase 0: Baseline

Targets:
- [docs/for-agents/current/reference.md](/home/higorprado/nixos/docs/for-agents/current/reference.md)
- [modules/hosts/aurelius.nix](/home/higorprado/nixos/modules/hosts/aurelius.nix)
- [docs/for-humans/workflows/106-deploy-aurelius.md](/home/higorprado/nixos/docs/for-humans/workflows/106-deploy-aurelius.md)

Changes:
- classify every recommendation in the temporary roadmap as one of:
  - already present
  - tracked runtime work
  - manual/operator workflow
  - explicitly deferred
- freeze backup/restic as deferred for this cycle
- record the service-layout rule for this project:
  - prefer declarative service-owned state
  - do not treat `~/services/*` or loose `docker-compose.yml` files as the
    default tracked design

Validation:
- verify the current runtime and docs targets by reading the tracked owners
- use `rg` to confirm which proposed features and services already exist
- run `./scripts/check-docs-drift.sh`

Diff expectation:
- documentation-only baseline and planning slice

Commit target:
- `docs(aurelius): rewrite roadmap in repo terms`

### Phase 1: Service Foundation

Targets:
- [modules/hosts/aurelius.nix](/home/higorprado/nixos/modules/hosts/aurelius.nix)
- [modules/features/system/docker.nix](/home/higorprado/nixos/modules/features/system/docker.nix)
- possibly a new narrow owner for Mosh if it is accepted as real tracked runtime

Changes:
- add `nixos.docker` and `homeManager.docker` to `aurelius`
- define the baseline exposure policy for future services:
  - keep public ports closed by default
  - prefer localhost listeners or Tailscale-only access
  - do not open public ports just because a service exists
- decide the canonical state layout for service data:
  - `StateDirectory`
  - service-native `dataDir`
  - `/var/lib/<service>` or `/srv/<service>`
  - not home-directory service roots
- decide whether Mosh belongs in the first cut:
  - if yes, model it through the right owner
  - if no, keep it out of the first implementation slice

Validation:
- `./scripts/run-validation-gates.sh structure`
- `nix eval .#nixosConfigurations.aurelius.config.system.build.toplevel.drvPath`
- `nix build --no-link .#nixosConfigurations.aurelius.config.system.build.toplevel`

Diff expectation:
- `aurelius` gains a clean foundation for containers and future services

Commit target:
- `feat(aurelius): add service foundation`

### Phase 2: Remote Dev Headless

Targets:
- [modules/hosts/aurelius.nix](/home/higorprado/nixos/modules/hosts/aurelius.nix)
- [modules/features/dev/editor-neovim.nix](/home/higorprado/nixos/modules/features/dev/editor-neovim.nix)
- [modules/features/dev/packages-toolchains.nix](/home/higorprado/nixos/modules/features/dev/packages-toolchains.nix)
- [modules/features/dev/dev-tools.nix](/home/higorprado/nixos/modules/features/dev/dev-tools.nix)
- [modules/features/dev/dev-devenv.nix](/home/higorprado/nixos/modules/features/dev/dev-devenv.nix)
- [modules/features/shell/core-user-packages.nix](/home/higorprado/nixos/modules/features/shell/core-user-packages.nix)

Changes:
- add the remote-dev feature set that the roadmap is really asking for:
  - `nixos.editor-neovim`
  - `nixos.packages-toolchains`
  - `homeManager.editor-neovim`
  - `homeManager.dev-tools`
  - `homeManager.dev-devenv`
  - `homeManager.terminal-tmux`
  - `homeManager.tui-tools`
  - `homeManager.starship`
  - `homeManager.monitoring-tools`
  - `homeManager.packages-toolchains`
- keep tmux as the primary persistence model for remote development
- verify the ARM-specific `btop-cuda` concern before changing it
- if `btop-cuda` is wrong on `aarch64`, fix it in the narrow feature owner
  instead of papering over it with an ugly host-local override

Validation:
- `./scripts/run-validation-gates.sh structure`
- `nix eval .#nixosConfigurations.aurelius.config.home-manager.users.higorprado.home.stateVersion`
- `nix build --no-link .#nixosConfigurations.aurelius.config.home-manager.users.higorprado.home.path`
- `nix build --no-link .#nixosConfigurations.aurelius.config.system.build.toplevel`

Diff expectation:
- `aurelius` becomes a real remote-development target instead of only a thin server

Commit target:
- `feat(aurelius): add remote dev environment`

### Phase 3: Binary Cache

Targets:
- a new narrow owner in `modules/features/system/` for an Attic server
- [modules/hosts/aurelius.nix](/home/higorprado/nixos/modules/hosts/aurelius.nix)
- possibly [modules/hosts/predator.nix](/home/higorprado/nixos/modules/hosts/predator.nix) for client wiring

Changes:
- model Attic as tracked declarative runtime, not as a loose home-directory compose stack
- choose implementation in this order:
  1. native NixOS service if simple and stable enough
  2. repo-owned containerized service if native is not the right fit
- keep quota, data path, and secrets explicit
- separate server bring-up from client integration if that reduces risk

Validation:
- `./scripts/run-validation-gates.sh structure`
- `nix build --no-link .#nixosConfigurations.aurelius.config.system.build.toplevel`
- if predator client wiring is added, build predator too

Diff expectation:
- `aurelius` can host a binary cache without ad hoc service files in home

Commit target:
- `feat(attic): add aurelius binary cache server`
- `feat(predator): wire attic cache client`

### Phase 4: Forgejo

Targets:
- a new narrow owner in `modules/features/system/` for Forgejo
- [modules/hosts/aurelius.nix](/home/higorprado/nixos/modules/hosts/aurelius.nix)

Changes:
- add Forgejo as tracked runtime with persistent service-owned state
- prefer a real service owner over loose compose definitions in `~/services/forgejo`
- keep credentials, registration policy, and SSH/HTTP exposure explicit
- defer mirror automation until the service itself is stable

Validation:
- `./scripts/run-validation-gates.sh structure`
- `nix build --no-link .#nixosConfigurations.aurelius.config.system.build.toplevel`

Diff expectation:
- `aurelius` gains a declarative private Git service

Commit target:
- `feat(forgejo): add aurelius git service`

### Phase 5: Observability

Targets:
- a narrow owner for node exporter
- possibly separate owners for Prometheus and Grafana
- [modules/hosts/aurelius.nix](/home/higorprado/nixos/modules/hosts/aurelius.nix)

Changes:
- start with the smallest high-signal piece: node exporter
- add Prometheus and Grafana only as explicitly owned follow-up services
- avoid a single broad `monitoring-stack` bucket unless the runtime genuinely
  stays simpler that way
- keep retention and state paths explicit

Validation:
- `./scripts/run-validation-gates.sh structure`
- `nix build --no-link .#nixosConfigurations.aurelius.config.system.build.toplevel`

Diff expectation:
- `aurelius` exposes host metrics first, then grows into a monitoring host in controlled slices

Commit target:
- `feat(monitoring): add aurelius node exporter`
- `feat(monitoring): add prometheus and grafana`

### Phase 6: GitHub Runner

Targets:
- a narrow owner in `modules/features/system/` for GitHub Actions runner support
- [modules/hosts/aurelius.nix](/home/higorprado/nixos/modules/hosts/aurelius.nix)

Changes:
- prefer native `services.github-runners.*` over a generic third-party container
- keep token material private and file-based
- define labels, workdir, and runtime expectations explicitly
- wire GitHub workflows only after the local runner service is stable

Validation:
- `./scripts/run-validation-gates.sh structure`
- `nix build --no-link .#nixosConfigurations.aurelius.config.system.build.toplevel`

Diff expectation:
- the runner becomes part of tracked runtime rather than an external sidecar

Commit target:
- `feat(ci): add aurelius github runner`

### Phase 7: Access Model and Exit Node

Targets:
- [modules/features/system/tailscale.nix](/home/higorprado/nixos/modules/features/system/tailscale.nix)
- [modules/hosts/aurelius.nix](/home/higorprado/nixos/modules/hosts/aurelius.nix)
- [modules/hosts/predator.nix](/home/higorprado/nixos/modules/hosts/predator.nix)

Changes:
- decide the HTTP access model only after real services exist:
  - direct Tailscale access
  - Tailscale Serve
  - Caddy
- avoid adding a reverse proxy before there is enough real service surface to justify it
- evaluate `useRoutingFeatures = "server"` only when exit-node support actually enters scope
- keep operator shortcuts in the host owner that uses them:
  - predator-owned access abbreviations stay in predator
  - no generic shell feature pollution

Validation:
- `./scripts/run-validation-gates.sh structure`
- `nix build --no-link .#nixosConfigurations.aurelius.config.system.build.toplevel`
- if predator changes, build predator too

Diff expectation:
- service exposure and exit-node behavior are added only when they have real consumers

Commit target:
- `feat(tailscale): enable aurelius exit-node mode`
- `feat(predator): add aurelius operator shortcuts`

### Phase 8: Service-Owned Maintenance

Targets:
- the new feature owners introduced in phases 3 through 7
- only a host-local owner if a timer or check has no better owner

Changes:
- keep cleanup, GC, retention, and health checks with the service that owns them
- do not introduce a broad `aurelius-automation.nix` bucket unless a specific
  residual concern survives that genuinely has no narrower home
- treat playground/container experimentation as a non-goal for tracked runtime
  until a concrete need appears

Validation:
- per-service validation as each owner is introduced

Diff expectation:
- maintenance stays co-located with service ownership and does not create a new
  abstract subsystem

Commit target:
- `refactor(aurelius): co-locate maintenance with service owners`

## Risks

- The temporary roadmap invites a hybrid model: half declarative runtime, half
  home-directory compose files and manual operator steps. If followed literally,
  it would weaken ownership clarity again.
- `aurelius` is `aarch64`, so desktop-leaning packages and service assumptions
  need explicit verification before being promoted into the host.
- Infra services bring secrets, state, quota, and exposure concerns. The risk is
  not just a failed build; it is also wrong ownership or leaking sensitive data
  into tracked files.
- Attic, Forgejo, Grafana, Prometheus, and runner could easily balloon into five
  separate subprojects. The plan needs narrow slices to keep momentum.
- Exposure decisions made too early can add attack surface or needless complexity.

## Definition of Done

- An active plan exists for `aurelius` in repo-native dendritic terms.
- Backup is explicitly deferred and does not contaminate the current execution plan.
- Each major concern has a proposed owner, target files, validation gates, and
  commit split.
- The active plan does not recommend `docker-compose.yml` in home as the
  canonical tracked model.
- The active plan does not recommend a generic automation bucket by default.
- The active plan follows the repository scaffold and living-doc rules.
