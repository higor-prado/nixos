# Aurelius Next Steps Dendritic Plan

## Goal

Turn `aurelius` into a repo-native server and remote-development host using the
existing dendritic runtime of this repo, while translating the temporary
generic roadmap material into explicit host composition,
narrow feature owners, and declarative service ownership. Backups are
intentionally excluded for now.

## Scope

In scope:
- reframe the temporary external roadmap material into repo-native tracked work
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
- The currently kept `aurelius` slices now have explicit status instead of a
  blanket "done" label:
  - complete:
    - Docker foundation on `aurelius`
    - cross-arch `dev-devenv` fix
    - node exporter as a local-only metrics primitive
    - Prometheus as a local-only metrics collector on `aurelius`
    - Forgejo with predator-consumable Tailscale access
    - Attic shared cache with predator producer and consumer flow proved end to end
  - partial:
    - remote-dev baseline because the activated predator-side `amdev`
      workflow is still blocked by the real access path
- The proof-based reclassification is tracked by
  [053-aurelius-no-false-done-plan.md](/home/higorprado/nixos/docs/for-agents/archive/plans/053-aurelius-no-false-done-plan.md).
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
- The `aurelius` host owner is organized like the healthy `predator` owner:
  - grouped `nixos*` import lists by concern
  - grouped `hm*` import lists by concern
  - no raw inline `home-manager.users.${user}.imports = [ ... ]` dump
- Each new concern has a clear owner:
  - host composition in `modules/hosts/aurelius.nix`
  - reusable service behavior in narrow `modules/features/system/*.nix`
  - machine tuning in `hardware/aurelius/*`
  - secrets and tokens in private overrides, not tracked files
- No active plan instructs the repo to rely on `docker-compose.yml` under the
  user's home directory as the canonical tracked service model.
- No active plan introduces a generic automation bucket when service-owned
  timers/maintenance would be clearer.
- Service slices distinguish three different states explicitly:
  - enabled in declarative runtime
  - healthy on the host itself
  - consumable through the intended access path from the real client or operator host
- No service slice is treated as complete merely because `systemd` is green or
  the service answers on `127.0.0.1` inside `aurelius`.
- The roadmap is ordered by real dependency and value:
  1. foundation
  2. remote development
  3. service stack
  4. access/exposure
  5. service-owned maintenance
- Backup is explicitly deferred and does not leak into the implementation plan.

## Quality Bar

Every implementation slice must satisfy all of the following:

1. **Ownership discipline**
   - host files only compose published modules and concrete host state
   - no inline module attrsets mixed into import lists
   - no secret-file conditionals, `pathExists` gating, or host-owner hacks
   - no “temporary” tracked glue that would be embarrassing to keep if the
     slice became permanent

2. **Host-owner readability**
   - `aurelius.nix` must remain visually comparable to `predator.nix`
   - imports must stay grouped by concern in named local lists
   - no long raw inline payloads dumped directly into `imports`,
     `home-manager.users.*`, or ad hoc `let` clutter

3. **Feature reuse before new code**
   - reuse an existing published owner whenever the concern already exists
   - if a new module is needed, it must own a real concern, not just hide an
     ugly inline block from the host file
   - do not create buckets like `*-stack`, `*-automation`, or `*-runtime`
     unless the concern is genuinely cohesive and narrow

4. **Code shape must be production-worthy**
   - no fallback logic that hides real misconfiguration
   - no half-configured service slices that still need obvious tracked cleanup
   - no local “for now” structure that violates the repo pattern
   - if the clean version is not ready, the slice stays deferred

5. **Access semantics are explicit**
   - each service must state whether it is:
     - local-only on `aurelius`
     - reachable from `predator`
     - reachable via Tailscale/Serve/reverse proxy
   - `ROOT_URL`, bind address, firewall, and operator docs must agree

6. **Validation matches the claim**
   - local-only services must be tested from `aurelius`
   - remotely consumed services must be tested from the real consumer path
     (normally `predator`)
   - “service is active” is not enough when the slice claims operator access
   - architecture-sensitive changes must be validated on the real target path,
     not assumed from local `x86_64` success

7. **Docs describe reality, not aspiration**
   - workflow docs may document only access paths that were actually validated
   - plans must not silently upgrade a local-only service into a remotely
     consumable one
   - any new guidance added to living docs must match the repo rules and the
     current runtime shape exactly

8. **Completion requires runtime proof**
   - each slice must define the exact command or probe that proves the intended
     behavior
   - if that proof does not exist yet, the slice remains partial or deferred
   - “it builds” is necessary but not sufficient when the slice claims runtime
     behavior, operator workflow, or cross-host usability

9. **Service semantics stay in the service owner**
   - URLs, bind policy, and service-specific firewall openings belong in the
     feature owner, not in the host file
   - host files should compose the owner, not restate the service's meaning
   - move a setting into the host only if it is truly concrete host-only state
     rather than service behavior

10. **Service execution must follow a two-step proof flow**
   - first prove the owner shape is correct:
     - host composes the feature cleanly
     - service semantics live in the owner
     - docs do not overclaim
   - then prove runtime from both ends that matter:
     - the host itself
     - the real consumer path
   - do not mix these into one fuzzy “working” judgment

## Phases

### Phase 0: Baseline

Targets:
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
- reshape `aurelius.nix` so the host owner stays readable while it grows:
  - `nixosInfrastructure`
  - `nixosCoreServices`
  - `nixosUserTools`
  - `hmUserTools`
  - `hmShell`
  - `hmDev`
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
- accept Mosh as part of the remote-dev baseline:
  - server-side enablement through a narrow published owner
  - client install through a published HM owner
  - `aurelius`-specific fish abbreviations stay predator-owned
- keep the host owner shape consistent with `predator` instead of regressing into
  a long inline HM imports list
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
- use the native `services.atticd` NixOS module as the default implementation:
  - it already provides `StateDirectory = "atticd"`
  - it already supports a private `environmentFile`
  - it already validates structured TOML settings
- keep quota, data path, bind address, and secrets explicit
- derive only the narrow local server facts in tracked runtime:
  - bind address
  - local publisher endpoint
  - cache name from `config.networking.hostName`
- keep deployment-specific consumer facts out of tracked runtime:
  - public endpoint
  - public signing key
  - any host-private advertised URL
- if a predator-side consumer owner is added, it must read only narrow private
  deployment facts and must not hardcode them in the host owner or feature owner
- treat a containerized Attic deployment as fallback only if a concrete native-module
  limitation appears during implementation
- separate server bring-up from client integration if that reduces risk

Validation:
- `./scripts/run-validation-gates.sh structure`
- `nix build --no-link .#nixosConfigurations.aurelius.config.system.build.toplevel`
- verify `attic-cache-bootstrap.service` exits successfully on `aurelius`
- verify `attic-watch-store.service` stays active on `aurelius`
- build a new proof path on `aurelius` and verify the watch-store service pushes
  it automatically
- verify the public cache endpoint serves `nix-cache-info`
- if predator client wiring is added, build predator too
- if the slice claims predator can consume the cache, prove it from predator
  with the real cache endpoint and client config in place

Diff expectation:
- `aurelius` can host a binary cache without ad hoc service files in home
- the tracked runtime owns the producer path
- consumer deployment facts remain private and narrow
- if the slice stops before normal predator builds can consume the cache
  automatically, it stays explicitly partial

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
- treat local-only bring-up and remote access as two separate states:
  - local-only on `127.0.0.1` is acceptable only as an intermediate slice
  - local-only bring-up does not satisfy the final Forgejo goal for this roadmap
  - remote consumption from `predator` requires a later explicit access slice

Validation:
- `./scripts/run-validation-gates.sh structure`
- `nix build --no-link .#nixosConfigurations.aurelius.config.system.build.toplevel`
- verify the host file still only composes `nixos.forgejo` and does not carry
  Forgejo-specific URL, firewall, or service attrsets
- if the slice is local-only:
  - verify `forgejo.service` is active on `aurelius`
  - verify the listener is bound exactly as declared
  - verify `curl -I` locally on `aurelius`
- if the slice claims remote usability from `predator`:
  - verify name resolution or the chosen access path from `predator`
  - verify `curl -I` from `predator` against the real URL
  - verify `ROOT_URL` matches the validated access path

Diff expectation:
- `aurelius` gains either:
  - a validated intermediate local-only Forgejo bring-up that remains explicitly
    partial in the roadmap
  - or a validated predator-consumable private Git service once the access model
    is actually implemented

Commit target:
- `feat(forgejo): add aurelius local-only bring-up`
- `feat(forgejo): expose aurelius git service to predator`

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
- local-only exporter slices must be proved from `aurelius`
- any Prometheus/Grafana slice that claims remote use must be proved from the
  real consumer path

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
- move service URLs in docs only after the chosen access model is actually live
- do not document `http://aurelius:<port>` as a consumer URL unless predator
  can really resolve and reach it

Validation:
- `./scripts/run-validation-gates.sh structure`
- `nix build --no-link .#nixosConfigurations.aurelius.config.system.build.toplevel`
- if predator changes, build predator too
- verify the service owner still owns its own URL and exposure semantics
- verify the selected access path from predator with the real consumer command
- verify the documented URL matches the tested access path exactly

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
- The plan now encodes the same quality standard expected from the runtime:
  - clean host-owner composition
  - narrow real feature ownership
  - no tracked transitional glue
  - no hidden misconfiguration fallbacks
- Service-oriented slices now require explicit access semantics:
  - local-only
  - predator-consumable
  - externally exposed
- No slice is considered complete based only on local host health when the
  intended user story is remote consumption.
- Operator-facing docs and abbreviations may describe only the access path that
  has been validated from the actual consumer host.
- A slice is not “done” merely because it evaluates or builds; it must also
  satisfy the repo's structural style and runtime-proof requirements.
- Removing a bad slice from active runtime counts only as integrity repair; it
  does not count as delivering the capability that the roadmap still intends to
  add.
- A deferred slice is not a completed slice. It remains open work until it is:
  - explicitly removed from the roadmap scope
  - or implemented with its real access model and proof bar
- For service slices like Forgejo, local-only health is never the final success
  condition when the intended user story is real operator use from `predator`.
- Before a service slice is called complete, verify that the host file remains a
  pure composition owner and that service semantics did not leak back into the
  host during implementation.
