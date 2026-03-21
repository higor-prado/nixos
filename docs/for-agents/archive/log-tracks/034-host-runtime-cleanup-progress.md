# Runtime Simplification Progress

## Status

In progress

## Related Plan

- [034-host-runtime-cleanup-plan.md](../plans/034-host-runtime-cleanup-plan.md)

## Baseline

- Current branch: `dendritic-without-den`
- Dirty tracked file before execution:
  - `flake.lock`
- Confirmed baseline facts:
  - `flake.modules` is a real `flake-parts` registry of `deferredModule`s
  - the `dendritic` example consumes it via local aliases such as
    `inherit (config.flake.modules) nixos`
  - the committed runtime still uses the artificial `repo.context` carrier
  - the rejected uncommitted slice tried to clean that up by introducing
    `generic.repo-context` and `contextModule`, which is also the wrong shape

## Slices

### Slice 1

- Opened the execution track.
- Audited the runtime against the current repo and the `dendritic` reference.
- Confirmed that `repo.context` was being used as a transport bag rather than a
  narrow semantic fact.

Validation:
- `rg -n "repo\\.context\\.(hostName|host|userName|user)" modules scripts tests -g '*.nix' -g '*.sh'`
- `rg -n "config\\.flake\\.modules\\.(nixos|homeManager)" modules/hosts -g '*.nix'`

Diff result:
- none

Commit:
- none

### Slice 2

- Re-read the `dendritic` reference more carefully:
  - `example/modules/meta.nix`
  - `example/modules/shell.nix`
  - `example/modules/admin.nix`
  - `example/modules/desktop.nix`
  - `example/modules/nixos.nix`
  - `example/modules/flake-parts.nix`
  - `example/modules/systems.nix`
  - `README.md`
- Tightened the diagnosis:
  - the problem is not only `repo.context`
  - the problem is any schema or option layer that behaves like transport
    infrastructure instead of structural composition or a narrow semantic fact
- Rewrote the plan with that stricter reading.

Validation:
- `find ~/git/dendritic/example/modules -maxdepth 1 -type f -name '*.nix' | sort`
- `sed -n '1,220p' ~/git/dendritic/example/modules/meta.nix`
- `sed -n '1,220p' ~/git/dendritic/example/modules/shell.nix`
- `sed -n '1,220p' ~/git/dendritic/example/modules/admin.nix`
- `sed -n '1,220p' ~/git/dendritic/example/modules/desktop.nix`
- `sed -n '1,220p' ~/git/dendritic/example/modules/nixos.nix`
- `sed -n '1,220p' ~/git/dendritic/example/modules/flake-parts.nix`
- `sed -n '1,220p' ~/git/dendritic/example/modules/systems.nix`
- `sed -n '1,260p' ~/git/dendritic/README.md`

Diff result:
- plan rewritten with a stricter dendritic reading

Commit:
- none

### Slice 3

- Executed Phase 0 of the rewritten plan.
- Discarded the uncommitted runtime-cleanup slice that had introduced:
  - `generic.repo-context`
  - `contextModule`
  - templates/docs/fixtures teaching that shape
- Preserved:
  - `flake.lock`
  - the rewritten plan
  - this progress log

Validation:
- `git status --short`
- `git diff --name-only`
- `rg -n "generic\\.repo-context|contextModule" modules templates tests docs -g '!docs/for-agents/archive/**'`

Diff result:
- only these paths remain dirty after the abort:
  - `flake.lock`
  - `docs/for-agents/plans/034-host-runtime-cleanup-plan.md`
  - `docs/for-agents/current/034-host-runtime-cleanup-progress.md`

Commit:
- none

## Final State

### Slice 4

- Replaced verbose `config.flake.modules.<class>.*` host references with local
  aliases via `inherit (config.flake.modules) nixos homeManager`.
- Aligned real hosts, templates, fixture hosts, onboarding docs, and the host
  skeleton generator to that shape.

Validation:
- `bash tests/scripts/new-host-skeleton-fixture-test.sh`
- `./scripts/check-docs-drift.sh`
- `./scripts/run-validation-gates.sh structure`

Diff result:
- host composition got shorter without introducing helper framework code

Commit:
- none

### Slice 5

- Removed the artificial `repo.context` carrier from the tracked runtime.
- Deleted `nixos.repo-context`, `homeManager.repo-context`, and the
  `mkRepoContextOptions` carrier declaration.
- Moved host-aware feature dependencies to the owners that actually need them:
  - direct top-level `inputs` capture in `dms`, `niri`, `desktop-apps`,
    `dms-wallpaper`, `music-client`, and `theme-zen`
  - local `customPkgs` derivation from `pkgs + inputs` inside the HM features
    that need custom packages
  - `config.custom.user.name` for the selected tracked user in lower-level
    NixOS modules
- Simplified `predator`, `aurelius`, templates, and fixture hosts accordingly.
- Deleted the dead `lib/primary-tracked-user.nix` helper.

Validation:
- `./scripts/check-config-contracts.sh`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`
- `bash tests/scripts/run-validation-gates-fixture-test.sh`
- `bash tests/scripts/new-host-skeleton-fixture-test.sh`

Diff result:
- no tracked runtime code under `modules/`, `scripts/`, `tests/`, or
  `templates/` still imports or assigns `repo.context`

Commit:
- none

### Slice 6

- Updated the living docs and gate text to teach the new pattern:
  - explicit top-level facts
  - direct flake inputs captured by the owner
  - existing lower-level state such as `config.home.username`, `osConfig`, and
    `config.networking.hostName`
- Tightened the extension-contract helper so the tracked-user contract is
  checked against the host owner declaration instead of a fake runtime carrier.
- Fixed the current progress log to stop tripping the public-safety gate with
  absolute home paths.

Validation:
- `./scripts/check-docs-drift.sh`
- `./scripts/run-validation-gates.sh structure`
- `bash tests/scripts/gate-cli-contracts-test.sh`
- `./scripts/check-repo-public-safety.sh`

Diff result:
- living docs no longer teach `repo.context`

Commit:
- none

### Slice 7

- Replaced the overmodeled `repo.users.<name>.userName` surface with the single
  repo-wide `username` fact, matching the shape used by the `dendritic`
  reference more closely.
- Simplified real hosts, templates, fixtures, and living docs to consume
  `config.username`.
- Tightened `modules/options/repo-runtime-contracts.nix` wording so
  `custom.user.name` is documented as the concrete selected-user fact instead
  of a fake "compatibility-only" story.

Validation:
- `./scripts/check-config-contracts.sh`
- `bash tests/scripts/new-host-skeleton-fixture-test.sh`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`
- `./scripts/check-docs-drift.sh`

Diff result:
- `repo.users.*` disappeared from tracked runtime code and living docs

Commit:
- none

## Final State

- Phase 0 through the main carrier-removal slices completed
- the canonical runtime no longer depends on `repo.context`
- host-aware lower-level modules now use direct flake inputs, local `pkgs`
  derivation, narrow selected-user facts, or existing lower-level state
- the tracked repo-wide user identity is now the single `username` fact
- next useful step is to re-audit whether `custom.user.name` should stay as the
  long-term selected-user contract name or be renamed to something even more
  semantically direct
