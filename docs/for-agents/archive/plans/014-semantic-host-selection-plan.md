# Semantic Host Selection Plan

Date: 2026-03-10
Status: planned

Execution log:
- `docs/for-agents/current/016-semantic-host-selection-progress.md`

## Goal

Replace the current ugly `llm-agents` host-name branch with a den-native
pattern:

- host files declare semantic selections
- features consume semantic host data
- features do not inspect host identity just to decide what to install

Also identify other places in the repo where the same pattern is a better fit
than directly consuming raw `host.inputs` / `host.customPkgs` / package-set
universes.

## Design Rule

Preferred rule:

1. Host modules own selection policy.
2. Feature modules consume already-selected semantic values.
3. Use `den.lib.parametric.exactly` when the feature depends on host context.
4. Do not use `provides` / `mutual-provider` for ordinary host feature
   selection.
5. Avoid `host.name == ...` inside shared features unless host identity is
   truly the behavior being modeled.

This matches den patterns seen in:
- ~/git/den/modules/aspects/provides/user-shell.nix
- ~/git/den/modules/aspects/provides/define-user.nix
- ~/git/den/modules/aspects/provides/hostname.nix
- ~/git/den/templates/ci/modules/features/user-host-bidirectional-config.nix

## Current Problem

Current state in `modules/features/dev/llm-agents.nix`:

- one shared feature owns both HM and NixOS package placement
- but it contains this host policy:
  - `host.name == "aurelius"`

That means the feature still decides *which host gets which package*.

This is functional, but it is not the prettiest den pattern because host policy
is living in the feature instead of the host.

## Recommended Target Shape

Introduce a semantic host selection contract in the host context, for example:

- `host.llmAgents.homePackages`
- `host.llmAgents.systemPackages`

Then:

- `modules/hosts/predator.nix` selects the HM tools it wants
- `modules/hosts/aurelius.nix` selects the system package it wants
- `modules/features/dev/llm-agents.nix` becomes a dumb bridge:
  - HM gets `host.llmAgents.homePackages`
  - NixOS gets `host.llmAgents.systemPackages`

### Example shape

Host:

```nix
llmAgents = {
  homePackages = with llmAgentsPkgs; [
    claude-code
    codex
    crush
    kilocode-cli
    opencode
  ];
  systemPackages = [ ];
};
```

```nix
llmAgents = {
  homePackages = [ ];
  systemPackages = with llmAgentsPkgs; [ openclaw ];
};
```

Feature:

```nix
den.aspects.llm-agents = den.lib.parametric.exactly {
  includes = [
    ({ host, ... }: {
      nixos.environment.systemPackages = host.llmAgents.systemPackages;
      homeManager.home.packages = host.llmAgents.homePackages;
    })
  ];
};
```

## Scope

In scope:
- refactor `llm-agents` to semantic host selection
- add the needed host schema extension
- update docs and progress tracking
- audit similar patterns in the repo and classify them

Out of scope:
- broad replacement of every `host.inputs` / `host.customPkgs` use
- changing flake inputs
- changing package contents

## Repo Audit: Where Else This Pattern Applies

This section is the key result of the additional repo analysis.

### High-confidence candidates

1. `modules/features/dev/llm-agents.nix`
   - Problem today:
     - feature chooses host behavior via `host.name == "aurelius"`
   - Better pattern:
     - host declares selected HM/system package lists
   - Priority: `P0`

2. `modules/features/desktop/niri.nix`
   - Current behavior:
     - feature chooses package variant from `host.inputs.niri.packages.${system}.niri-unstable`
   - Why it is a candidate:
     - picking `stable` vs `unstable` is a host policy decision, not feature behavior
   - Better pattern:
     - host declares `desktopPackages.niri` or similar semantic package slot
   - Priority: `P1`

### Medium-confidence candidates

3. `modules/features/desktop/gui-apps.nix`
   - Current behavior:
     - feature reaches into `host.inputs.zen-browser.packages...default`
   - Better pattern:
     - host declares selected browser package as semantic data
   - Priority: `P2`

4. `modules/features/desktop/theme-zen.nix`
   - Current behavior:
     - feature reaches into `host.customPkgs.catppuccin-zen-browser`
   - Better pattern:
     - host declares selected theme asset package if there is or may be host policy around it
   - Priority: `P2`

5. `modules/features/desktop/dms-wallpaper.nix`
   - Current behavior:
     - feature reaches into `host.customPkgs.dms-awww`
   - Better pattern:
     - host declares semantic package if host choice/divergence is expected
   - Priority: `P2`

6. `modules/features/desktop/music-client.nix`
   - Current behavior:
     - feature reaches into `host.customPkgs.rmpc`
   - Better pattern:
     - host declares semantic music-client package if host choice/divergence is expected
   - Priority: `P2`

### Low-confidence / leave alone for now

7. Direct `host.inputs` / `host.customPkgs` use with no host-selection pressure
   - These are not automatically antipatterns.
   - If a feature just consumes a shared package and there is no host policy,
     leaving it as-is can be fine.
   - Do not refactor these just for purity.

## Recommended Execution Order

1. Fix `llm-agents`
2. Re-evaluate whether `niri` should adopt the same pattern
3. Only then consider `gui-apps`, `theme-zen`, `dms-wallpaper`, `music-client`

This keeps the first slice small and proven before broadening the pattern.

## Phase 0: Baseline

Capture current behavior before touching the semantic contract.

Validation:
```bash
./scripts/run-validation-gates.sh structure
./scripts/run-validation-gates.sh predator
./scripts/run-validation-gates.sh aurelius
nix build path:$PWD#nixosConfigurations.predator.config.system.build.toplevel -o /tmp/semantic-host-before-predator-system
nix build path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path -o /tmp/semantic-host-before-predator-hm
```

## Phase 1: Add semantic host schema for llm-agents

Target:
- `modules/lib/den-host-context.nix`

Add a semantic slot for selected values, for example:
- `llmAgents.homePackages`
- `llmAgents.systemPackages`

Suggested type:
- `lib.types.raw` initially, if that keeps the slice small
- a typed submodule later only if there is clear benefit

Goal:
- the host context exposes selected package lists, not only the raw upstream package set

## Phase 2: Move selection policy into the hosts

Targets:
- `modules/hosts/predator.nix`
- `modules/hosts/aurelius.nix`

Change:
- each host declares its own semantic `llmAgents` package lists
- preserve the currently selected package set exactly

Expected result:
- `predator` owns the HM list
- `aurelius` owns the system list

## Phase 3: Make llm-agents a dumb consumer

Target:
- `modules/features/dev/llm-agents.nix`

Change:
- convert to `den.lib.parametric.exactly`
- remove `host.name == "aurelius"`
- consume only:
  - `host.llmAgents.homePackages`
  - `host.llmAgents.systemPackages`

Expected result:
- one pretty feature
- no host-identity logic
- no package-universe probing

## Phase 4: Docs and contracts

Targets:
- `docs/for-agents/002-den-architecture.md`
- `docs/for-agents/006-extensibility.md`
- `docs/for-agents/999-lessons-learned.md`
- `docs/for-agents/current/015-llm-agents-consolidation-progress.md`
- `docs/for-agents/current/016-semantic-host-selection-progress.md`

Update:
- docs should show semantic host selections as the preferred pattern when host
  policy exists
- leave raw `host.inputs` / `host.customPkgs` examples only where that is still
  truly acceptable

## Phase 5: Optional second-wave decision

Do not automatically refactor the other candidates in the same slice.

After `llm-agents` lands:
- decide whether `niri` should move to the same pattern next
- leave the `P2` candidates as a later readability pass unless they are being touched anyway

## Validation

Mandatory after the `llm-agents` refactor:
```bash
./scripts/check-docs-drift.sh
./scripts/run-validation-gates.sh structure
./scripts/run-validation-gates.sh predator
./scripts/run-validation-gates.sh aurelius
bash scripts/check-changed-files-quality.sh
nix build path:$PWD#nixosConfigurations.predator.config.system.build.toplevel -o /tmp/semantic-host-after-predator-system
nix build path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path -o /tmp/semantic-host-after-predator-hm
nix store diff-closures /tmp/semantic-host-before-predator-system /tmp/semantic-host-after-predator-system
nix store diff-closures /tmp/semantic-host-before-predator-hm /tmp/semantic-host-after-predator-hm
```

Expected diffs:
- `predator` system diff: empty
- `predator` HM diff: empty

Recommended extra checks:
```bash
nix eval --json path:$PWD#nixosConfigurations.predator.config.environment.systemPackages
nix eval --json path:$PWD#nixosConfigurations.aurelius.config.environment.systemPackages
```

## Commit Strategy

1. `refactor: add semantic llm agent host selections`
2. `docs: record semantic host selection pattern`

If the docs delta is tiny, one combined commit is also acceptable.

## Success Criteria

The work is successful when:
- `llm-agents` contains no host-name branching
- `llm-agents` consumes semantic host selections only
- host modules own the package choice policy
- docs describe this pattern clearly
- baseline vs final predator diffs are empty
- the repo has a clear shortlist of next candidates without forcing them now
