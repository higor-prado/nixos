# Niri Semantic Package Plan

Date: 2026-03-10
Status: planned

Execution log:
- `docs/for-agents/current/017-niri-semantic-package-progress.md`

## Goal

Refactor `modules/features/desktop/niri.nix` to use the same den-native semantic host selection pattern adopted for `llm-agents`:

- host files own package selection policy
- the feature consumes semantic host data
- the feature no longer reaches into `host.inputs.niri.packages.${system}.niri-unstable`

## Why This Is Worth Doing

Current shape in `modules/features/desktop/niri.nix`:

- the feature selects `niri-unstable` directly from the flake input
- that means package variant choice is owned by the feature, not by the host

That is acceptable when there is only one host, but it becomes an architectural
smell as soon as:

- another host wants `niri-stable`
- a test fixture wants a different package
- the repo wants to treat package channel choice as host policy

This is the same class of issue that `llm-agents` had before the semantic host
selection refactor.

## Current Real Usage

Current live usage is narrow:

- `modules/hosts/predator.nix` includes `niri`
- `predator` also includes `modules/desktops/dms-on-niri.nix`
- no other tracked host includes `niri`

That means the refactor can stay small and low-risk while still improving the
pattern.

## Recommended Target Shape

Introduce a semantic host slot, for example:

- `host.desktopPackages.niri`

Then:

- `modules/hosts/predator.nix` chooses the package
- `modules/features/desktop/niri.nix` simply consumes it

### Example

Host:

```nix
let
  desktopPackages = {
    niri = inputs.niri.packages.${system}.niri-unstable;
  };
in
{
  den.hosts.x86_64-linux.predator = {
    users.higorprado.classes = [ "homeManager" ];
    inherit inputs customPkgs llmAgents desktopPackages;
  };
}
```

Feature:

```nix
den.aspects.niri = den.lib.parametric.exactly {
  includes = [
    ({ host, ... }: {
      nixos = { config, lib, ... }: {
        programs.niri = {
          enable = true;
          package = host.desktopPackages.niri;
        };
      };
    })
  ];
};
```

## Design Rules

1. Keep the current behavior unchanged:
   - `predator` should still resolve to `niri-unstable`
2. Do not broaden scope to unrelated desktop package cleanup yet
3. Do not move composition-owned logic out of:
   - `modules/desktops/dms-on-niri.nix`
   - `modules/desktops/niri-standalone.nix`
4. Keep `custom.niri.standaloneSession` exactly as it is
5. Prefer `den.lib.parametric.exactly` for the feature if the final context use is exact

## Scope

In scope:
- add a semantic desktop package slot to host context
- move `niri` package choice into the host
- update `modules/features/desktop/niri.nix`
- update fixtures/docs/tests affected by the new host context contract

Out of scope:
- changing the actual chosen Niri version
- migrating Zen Browser / DMS / theme / music-client in the same slice
- changing desktop composition ownership

## Planned Host Context Change

Extend `modules/lib/den-host-context.nix` with a semantic desktop package slot, likely:

- `desktopPackages.niri`

Suggested shape:

```nix
desktopPackages = lib.mkOption {
  type = lib.types.submodule {
    options = {
      niri = lib.mkOption {
        type = lib.types.raw;
        description = "Selected Niri package for this host.";
      };
    };
  };
};
```

If a default is needed for simulation fixtures, use a narrow safe default only
if it does not hide missing host wiring. Otherwise keep it required and fix the
fixtures explicitly.

## Execution Phases

## Phase 0: Baseline

Capture current behavior.

Validation:
```bash
./scripts/run-validation-gates.sh structure
./scripts/run-validation-gates.sh predator
nix build path:$PWD#nixosConfigurations.predator.config.system.build.toplevel -o /tmp/niri-semantic-before-system
nix build path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path -o /tmp/niri-semantic-before-hm
```

Useful spot checks:
```bash
nix eval --json path:$PWD#nixosConfigurations.predator.config.programs.niri.package.name
nix eval --json path:$PWD#nixosConfigurations.predator.config.services.greetd.settings.default_session.command
```

## Phase 1: Add semantic desktop package host context

Target:
- `modules/lib/den-host-context.nix`

Change:
- add `desktopPackages.niri`

Goal:
- host context exposes semantic desktop package choice instead of making the
  feature inspect raw flake inputs

## Phase 2: Move package choice into predator

Target:
- `modules/hosts/predator.nix`

Change:
- define `desktopPackages.niri = inputs.niri.packages.${system}.niri-unstable`
- pass `desktopPackages` through `den.hosts...`

Important:
- keep the chosen package exactly the same as today

## Phase 3: Refactor the feature

Target:
- `modules/features/desktop/niri.nix`

Change:
- remove direct use of `host.inputs.niri.packages...`
- consume `host.desktopPackages.niri`
- if possible, tighten to `den.lib.parametric.exactly`

Goal:
- feature stops owning package variant policy

## Phase 4: Fix simulations, templates, and docs

Likely targets:
- `scripts/check-desktop-composition-matrix.sh`
- `docs/for-agents/002-den-architecture.md`
- `docs/for-agents/006-extensibility.md`
- `docs/for-humans/workflows/103-add-host.md`
- `docs/for-agents/current/017-niri-semantic-package-progress.md`

Potential fixture impact:
- only if any current host skeleton/sample now needs the new semantic slot

## Validation

Mandatory:
```bash
./scripts/check-docs-drift.sh
bash scripts/check-changed-files-quality.sh
./scripts/run-validation-gates.sh structure
./scripts/run-validation-gates.sh predator
nix build path:$PWD#nixosConfigurations.predator.config.system.build.toplevel -o /tmp/niri-semantic-after-system
nix build path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path -o /tmp/niri-semantic-after-hm
nix store diff-closures /tmp/niri-semantic-before-system /tmp/niri-semantic-after-system
nix store diff-closures /tmp/niri-semantic-before-hm /tmp/niri-semantic-after-hm
```

Recommended extra spot checks:
```bash
nix eval --json path:$PWD#nixosConfigurations.predator.config.programs.niri.package.name
nix eval --json path:$PWD#nixosConfigurations.predator.config.services.greetd.settings.default_session.command
nix eval --json path:$PWD#nixosConfigurations.predator.config.xdg.portal.config.niri
```

Expected diff result:
- predator system diff: empty
- predator HM diff: empty

## Risks

1. `niri` is coupled to greetd session command generation.
   - If the semantic package slot is wired incorrectly, the session command path changes.

2. Desktop composition matrix simulation may need the new host context data.
   - The script must be updated in the same slice if evaluation starts failing.

3. Tightening to `parametric.exactly` may require matching the exact context shape actually used by the host-owned HM/NixOS forwarding path.

## Commit Strategy

1. `refactor: move niri package selection to host context`
2. `docs: record semantic niri package pattern`

If the docs delta is small, one combined commit is acceptable.

## Success Criteria

The work is successful when:
- `niri.nix` no longer reaches into `host.inputs.niri.packages`
- `predator` owns the selected Niri package
- current runtime behavior is unchanged
- baseline vs final predator diffs are empty
- docs show `niri` as the next canonical example of semantic host selection
