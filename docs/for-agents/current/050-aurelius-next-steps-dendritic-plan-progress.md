# Aurelius Next Steps Dendritic Plan Progress

## Status

In progress

## Related Plan

- [050-aurelius-next-steps-dendritic-plan.md](/home/higorprado/nixos/docs/for-agents/plans/050-aurelius-next-steps-dendritic-plan.md)

## Baseline

- Active branch: `aurelius-next-steps-plan`
- Temporary source material was reviewed and extracted into the active plan, and
  is no longer needed in the active docs surface.
- Current tracked `aurelius` owner:
  - [aurelius.nix](/home/higorprado/nixos/modules/hosts/aurelius.nix)
- Remote baseline via SSH:
  - `hostname` => `aurelius`
  - `uname -m` => `aarch64`
  - `systemctl --failed` returned no units in the short baseline check
- Local baseline evaluation:
  - `nix eval --raw path:$PWD#nixosConfigurations.aurelius.config.system.build.toplevel.drvPath`
    returned `/nix/store/66ya2x7aaghhs6rzqcadzd358fad5v41-nixos-system-aurelius-26.05.20260318.b40629e.drv`
- Pre-existing unrelated worktree noise remains outside this plan:
  - archived `048`
  - archived `049`

## Slices

### Slice 1

- Started Phase 1 foundation work with the smallest useful change:
  wire `nixos.docker` and `homeManager.docker` into the explicit `aurelius`
  host composition.
- Intentionally deferred in this slice:
  - Mosh
  - extra firewall decisions
  - any service stack beyond Docker
  - backup/restic
- Validation outcome so far:
  - `./scripts/run-validation-gates.sh structure` passed
  - `nix eval --raw path:$PWD#nixosConfigurations.aurelius.config.system.build.toplevel.drvPath`
    passed and returned a new `aurelius` system drv path
  - local `nix build` for both the system and HM path on the current `x86_64`
    machine failed because the derivations required `aarch64-linux`
  - validation was then switched to a remote `nh os build` using `aurelius` as
    both target and build host, which is the correct validation path for this
    host architecture

### Slice 2

- Started Phase 2 remote-dev wiring by adding the already-tracked dev features
  to [aurelius.nix](/home/higorprado/nixos/modules/hosts/aurelius.nix):
  - `nixos.editor-neovim`
  - `nixos.packages-toolchains`
  - `homeManager.dev-devenv`
  - `homeManager.dev-tools`
  - `homeManager.editor-neovim`
  - `homeManager.monitoring-tools`
  - `homeManager.packages-toolchains`
  - `homeManager.starship`
  - `homeManager.terminal-tmux`
  - `homeManager.tui-tools`
- Kept this slice focused on reusing existing owners only.
- Extended the remote-dev baseline with a narrow new owner for Mosh:
  - [mosh.nix](/home/higorprado/nixos/modules/features/system/mosh.nix)
    publishes:
    - `nixos.mosh`
    - `homeManager.mosh`
  - `aurelius` imports `nixos.mosh`
  - `predator` imports `homeManager.mosh`
  - `predator` owns the `adev` / `amdev` operator abbreviations locally
- Reshaped the host file to match the healthier `predator` pattern:
  - `nixosInfrastructure`
  - `nixosCoreServices`
  - `nixosUserTools`
  - `hmUserTools`
  - `hmShell`
  - `hmDev`
- This removed the raw inline `home-manager.users.${userName}.imports = [ ... ]`
  dump and kept the host owner readable as the remote-dev slice grew.
- Explicitly did not add:
  - new service owners
  - custom `aurelius`-specific automation
  - backup/runtime state layout for future services
- Validation outcome:
  - `./scripts/run-validation-gates.sh structure` passed
  - `nix eval --json path:$PWD#nixosConfigurations.aurelius.config.virtualisation.docker.enable`
    returned `true`
  - `nix eval --json path:$PWD#nixosConfigurations.aurelius.config.home-manager.users.higorprado.programs.tmux.enable`
    returned `true`
  - remote `nh os build path:$PWD#aurelius --target-host aurelius --build-host aurelius`
    failed during evaluation
- Blocker discovered:
  - [dev-devenv.nix](/home/higorprado/nixos/modules/features/dev/dev-devenv.nix)
    uses `builtins.readFile (pkgs.runCommand ...)` to materialize
    `xdg.configFile."direnv/direnvrc".text`
  - that shape forces a target-architecture derivation to be realized during
    evaluation
  - deploying `aurelius` from `predator` therefore fails when the target is
    `aarch64-linux` and the current machine is `x86_64-linux`
  - this is a real repo/runtime issue, not just a local validation mismatch
- Fix applied:
  - `xdg.configFile."direnv/direnvrc"` now uses `.source = lib.mkForce (...)`
    in
    [dev-devenv.nix](/home/higorprado/nixos/modules/features/dev/dev-devenv.nix)
    instead of forcing an eval-time `builtins.readFile`
  - this keeps the generated file while removing the cross-arch eval trap
- Post-fix validation:
  - `./scripts/run-validation-gates.sh structure` passed again
  - `./scripts/check-docs-drift.sh` passed
  - `nix eval --json path:$PWD#nixosConfigurations.aurelius.config.virtualisation.docker.enable`
    returned `true`
  - `nix eval --json path:$PWD#nixosConfigurations.aurelius.config.home-manager.users.higorprado.programs.tmux.enable`
    returned `true`
  - the rerun remote `nh os build ... --target-host aurelius --build-host aurelius`
    passed the old evaluation failure point, started real remote ARM builds, and
    finished successfully
  - remote validation therefore now confirms both:
    - the `dev-devenv` cross-arch evaluation bug is fixed
    - the `aurelius` docker + remote-dev baseline builds cleanly on the real
      target host
- Mosh validation:
  - `nix eval --json path:$PWD#nixosConfigurations.aurelius.config.programs.mosh.enable`
    returned `true`
  - `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`
    fetched/built the `mosh` client successfully for predator HM
  - the remote build finished successfully
  - `nh os test path:$PWD#aurelius --target-host aurelius --build-host aurelius`
    passed
  - runtime checks on `aurelius` confirmed:
    - `mosh` and `mosh-server` are installed
    - Docker is active
    - remote-dev CLI tools like `tmux`, `starship`, and `lazygit` are present
- Quality note:
  - this slice proved the server side and predator HM build path
  - it did not yet prove the activated predator-side `amdev` operator workflow

### Slice 3

- Started the smallest monitoring slice instead of jumping straight to a full
  observability stack.
- Added a narrow NixOS owner:
  - [node-exporter.nix](/home/higorprado/nixos/modules/features/system/node-exporter.nix)
- Wired `aurelius` to import `nixos.node-exporter`.
- Kept the exposure conservative:
  - `listenAddress = "127.0.0.1"`
  - `port = 9100`
  - `enabledCollectors = [ "systemd" ]`
- This keeps monitoring useful without opening a public port or inventing a
  broader monitoring bucket too early.
- Validation:
  - `nix eval --json path:$PWD#nixosConfigurations.aurelius.config.services.prometheus.exporters.node.enable`
    returned `true`
  - `nh os test path:$PWD#aurelius --target-host aurelius --build-host aurelius`
    passed
  - runtime checks on `aurelius` confirmed:
    - `prometheus-node-exporter.service` is `active` and `enabled`
    - the exporter listens only on `127.0.0.1:9100`
    - `curl http://127.0.0.1:9100/metrics` returns metrics successfully

### Slice 4

- Started the first service-hosting slice that does not require external
  secrets.
- Added a narrow NixOS owner:
  - a temporary Forgejo owner that was later removed from active runtime
- Wired `aurelius` to import `nixos.forgejo`.
- Kept the first cut intentionally conservative:
  - `HTTP_ADDR = "127.0.0.1"`
  - `HTTP_PORT = 3000`
  - `ROOT_URL = "http://127.0.0.1:3000/"`
  - `DISABLE_SSH = true`
  - `DISABLE_REGISTRATION = true`
  - `DEFAULT_PRIVATE = "private"`
- This gives `aurelius` a tracked local-only Forgejo service without exposing
  new public ports or depending on compose files in home.
- Validation:
  - `nix eval --json path:$PWD#nixosConfigurations.aurelius.config.services.forgejo.enable`
    returned `true`
  - `nh os test path:$PWD#aurelius --target-host aurelius --build-host aurelius`
    passed
  - runtime checks on `aurelius` confirmed:
    - `forgejo.service` is `active` and `enabled`
    - Forgejo listens only on `127.0.0.1:3000`
    - `curl -I http://127.0.0.1:3000` returns `HTTP/1.1 200 OK`
- Later re-audit result:
  - this slice was not actually complete
  - the service never had a proved consumer access model
  - a later attempt to "align" URL semantics was only cosmetic
  - the slice was therefore removed from active runtime instead of being kept
    under a false-done label

### Slice 5

- Attempted follow-up slices for Attic, GitHub runner, exit-node readiness, and
  Grafana/Prometheus were started after Slice 4.
- That work regressed the `aurelius` host owner into a bad non-repo pattern:
  - secret-dependent services were pushed into tracked host composition
  - inline module payloads were mixed directly into import lists
  - tracked docs started to normalize that degraded shape
- Those slices were therefore discarded from the active tracked runtime instead
  of being carried forward in an ugly transitional form.
- Active runtime after the reset remains limited to the clean validated slices:
  - docker foundation
  - remote dev baseline
  - cross-arch `dev-devenv` fix
  - Mosh
  - node exporter

## Final State

- Execution has started.
- Baseline facts have been recorded.
- Slice 1 (`docker` foundation) validated through a remote `aurelius` build.
- Slice 2 found a real cross-architecture blocker in
  [dev-devenv.nix](/home/higorprado/nixos/modules/features/dev/dev-devenv.nix),
  then fixed it in the narrow owner and completed remote validation.
- Slice 2 later received a real usability fix: `devc` no longer depends on a
  host-local repo clone at `~/nixos`.
- Slice 3 added node-exporter as a local-only monitoring primitive.
- Slice 4 was removed from active runtime because its access model was not
  actually solved.
- Slice 5 reset the later bad drift and kept only the clean validated runtime.
- Backup remains explicitly out of scope for this cycle.

## Current Proof Matrix

| Slice | Evaluates | Builds / deploys | Healthy on host | Usable by intended consumer | Status |
|------|------|------|------|------|------|
| Docker foundation | yes | yes | yes | n/a | complete |
| Remote dev baseline | yes | yes | yes | partially; `adev` path is documented, `amdev` not fully proved | partial |
| `dev-devenv` usability | yes | yes | yes | yes on `aurelius` for `devc list` / template materialization | complete |
| Mosh | yes | yes | server side yes | predator-side activated workflow not fully proved | partial |
| node exporter | yes | yes | yes | yes for local-only monitoring claim | complete |
| Forgejo | removed | removed | removed from active runtime | no proved consumer path | deferred |
