# Aurelius Quality Sweep Progress

## Status

Completed

## Related Plan

- [052-aurelius-quality-sweep.md](/home/higorprado/nixos/docs/for-agents/archive/plans/052-aurelius-quality-sweep.md)

## Baseline

- The quality sweep started after a second-pass review showed that several
  `aurelius` slices had been treated as more complete than they really were.
- Concrete findings at baseline:
  - `devc` existed on `aurelius`, but its default `DEVC_FLAKE` assumed
    `~/nixos`, which does not exist there
  - Forgejo was healthy locally, but its configured `ROOT_URL` implied a remote
    path that had not been validated and was not reachable from `predator`
  - the Mosh slice had only partial validation: server side plus predator HM
    build, not an activated predator-side workflow proof
  - the active progress log still contained contradictions and overstatements
  - temporary external source material was still sitting in
    `docs/for-agents/current/`

## Slices

### Slice 1

- Corrected runtime semantics:
  - [dev-devenv.nix](/home/higorprado/nixos/modules/features/dev/dev-devenv.nix)
    now embeds the tracked devenv templates in a small generated flake instead
    of assuming a repo clone at `~/nixos`
  - [dev-devenv.nix](/home/higorprado/nixos/modules/features/dev/dev-devenv.nix)
    no longer uses `lib.mkForce` for `direnv/direnvrc`
  - the then-tracked Forgejo slice was cosmetically re-aligned to local-only
    URL semantics instead of being honestly downgraded
- Corrected active docs:
  - removed the unvalidated `amdev` path from
    [106-deploy-aurelius.md](/home/higorprado/nixos/docs/for-humans/workflows/106-deploy-aurelius.md)
  - updated
    [05-dev-environment.md](/home/higorprado/nixos/docs/for-humans/05-dev-environment.md)
    so `devc` documentation matches the new embedded-template default
  - tightened
    [050-aurelius-next-steps-dendritic-plan.md](/home/higorprado/nixos/docs/for-agents/plans/050-aurelius-next-steps-dendritic-plan.md)
    and
    [050-aurelius-next-steps-dendritic-plan-progress.md](/home/higorprado/nixos/docs/for-agents/current/050-aurelius-next-steps-dendritic-plan-progress.md)
    to remove contradictions and overstatements
  - removed the temporary external source file from the active `current/`
    surface

- Validation completed for the corrected runtime semantics:
  - `./scripts/check-docs-drift.sh` passed
  - `./scripts/check-repo-public-safety.sh` passed
  - `./scripts/run-validation-gates.sh structure` passed
  - `nix eval --raw path:$PWD#nixosConfigurations.predator.config.system.build.toplevel.drvPath`
    passed
  - `nix eval --raw path:$PWD#nixosConfigurations.aurelius.config.system.build.toplevel.drvPath`
    passed
  - remote `nh os test path:$PWD#aurelius --target-host aurelius --build-host aurelius`
    passed
  - `ssh aurelius 'devc list'` now returns the embedded tracked templates
  - `ssh aurelius 'devc python <tmpdir>'` now materializes template files
  - `nix eval --raw path:$PWD#nixosConfigurations.aurelius.config.services.forgejo.settings.server.ROOT_URL`
    returned `http://127.0.0.1:3000/` during that sweep
  - `ssh aurelius 'curl -I http://127.0.0.1:3000'` returned `HTTP/1.1 200 OK`
  - `ssh aurelius 'curl http://127.0.0.1:9100/metrics'` returns exporter metrics

- Remaining honesty constraint:
  - the full activated predator-side `amdev` workflow is still not counted as
    proved in this sweep
  - the docs now stop claiming that path

## Final State

- Runtime and active docs were corrected relative to the baseline understood at
  that time.
- Behavioral proofs for `devc`, the then-local-only Forgejo slice, and node
  exporter were rerun on the real `aurelius` host.
- The full repo gate rerun completed successfully:
  - `./scripts/run-validation-gates.sh all`
  - `./scripts/check-docs-drift.sh`
  - `./scripts/check-repo-public-safety.sh`
  - `nix eval --raw path:$PWD#nixosConfigurations.predator.config.system.build.toplevel.drvPath`
  - `nix eval --raw path:$PWD#nixosConfigurations.aurelius.config.system.build.toplevel.drvPath`
- The Mosh slice is now classified honestly:
  - server side proved
  - predator HM build proved
  - full activated predator-side workflow still not counted as proved
- This archived sweep was later superseded by
  [053-aurelius-no-false-done-plan.md](/home/higorprado/nixos/docs/for-agents/archive/plans/053-aurelius-no-false-done-plan.md),
  which removed the Forgejo slice from active runtime instead of keeping the
  cosmetic local-only URL alignment.
