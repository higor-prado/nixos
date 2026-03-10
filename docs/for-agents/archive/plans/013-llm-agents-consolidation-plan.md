# LLM Agents Consolidation Plan

Date: 2026-03-10
Status: planned

Execution log:
- `docs/for-agents/current/015-llm-agents-consolidation-progress.md`

## Goal

Replace the current tiny `ai-*` feature files with a single dev-scoped feature:

- `modules/features/dev/llm-agents.nix`

The new file should own the whole repo-side LLM agent surface while keeping the
real host differences:
- desktop/user agents on `predator`
- server/system agent on `aurelius`

## Current State

Current files:
- `modules/features/ai/ai-claude-code.nix`
- `modules/features/ai/ai-codex.nix`
- `modules/features/ai/ai-crush.nix`
- `modules/features/ai/ai-kilocode.nix`
- `modules/features/ai/ai-openclaw.nix`
- `modules/features/ai/ai-opencode.nix`

Current host usage:
- `modules/hosts/predator.nix`
  includes:
  - `ai-claude-code`
  - `ai-codex`
  - `ai-crush`
  - `ai-kilocode`
  - `ai-opencode`
- `modules/hosts/aurelius.nix`
  includes:
  - `ai-openclaw`

Current implementation shape:
- five HM-only package wrappers
- one NixOS-only package wrapper
- no per-agent option schema
- no meaningful agent-local logic left in tracked code

That makes this a good consolidation candidate.

## Answer To The Design Question

Yes, there is an easy way to do it.

Recommended easy path:
- create one aspect `llm-agents`
- keep it in `modules/features/dev/llm-agents.nix`
- add user-level agents in `homeManager.home.packages`
- add `openclaw` in `nixos.environment.systemPackages`
- use host package availability to decide what actually lands on each host

This is the simplest approach because:
- there is no longer enough per-agent behavior to justify six files
- host includes become clearer
- the diff should stay semantically empty if package selection is preserved

## Recommended Architecture

## Public surface

One file:
- `modules/features/dev/llm-agents.nix`

One public aspect:
- `llm-agents`

## Behavior split inside that file

Inside `llm-agents`, keep two ownership zones:

1. **Home Manager user-level agents**
   - `claude-code`
   - `codex`
   - `crush`
   - `kilocode-cli`
   - `opencode`

2. **NixOS system-level agent**
   - `openclaw`

This keeps the single-file goal while preserving the real OS/HM split.

## Host-difference rule

Preferred rule:
- add a package only if the corresponding attr exists in `host.llmAgentsPkgs`

That avoids introducing explicit host-name checks into the feature.

Example policy:
- HM adds any of:
  - `claude-code`
  - `codex`
  - `crush`
  - `kilocode-cli`
  - `opencode`
  when present in `host.llmAgentsPkgs`
- NixOS adds `openclaw` only when present in `host.llmAgentsPkgs`

Why this is preferred:
- it is simple
- it is den-native
- it avoids growing a new host-selection contract just for these packages

## Fallback if availability-based selection is insufficient

If `openclaw` also exists on `predator` and that becomes undesirable, use one of
these narrower fallbacks:

1. host include split:
   - keep a single file, but define `llm-agents` and `llm-agents-server`
   - include `llm-agents` on predator and `llm-agents-server` on aurelius

2. explicit parametric host policy:
   - still one file
   - only gate the `openclaw` addition with a narrow host-level condition

Use this only if availability-based selection does not preserve the current result.

## Scope

In scope:
- create `dev/llm-agents.nix`
- replace host includes
- remove obsolete `ai/*`
- update docs and tracker files
- keep validation and diff-based proof

Out of scope:
- changing the `llm-agents` flake input itself
- introducing per-agent options
- rewriting unrelated dev feature boundaries

## Execution Phases

## Phase 0: Baseline

Capture current behavior before consolidation.

Validation:
```bash
./scripts/run-validation-gates.sh structure
./scripts/run-validation-gates.sh predator
./scripts/run-validation-gates.sh aurelius
nix build .#nixosConfigurations.predator.config.system.build.toplevel -o /tmp/llm-agents-before-predator-system
nix build .#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path -o /tmp/llm-agents-before-predator-hm
```

Recommended extra checks:
```bash
nix eval --json .#nixosConfigurations.predator.config.home-manager.users.higorprado.home.packages
nix eval --json .#nixosConfigurations.aurelius.config.environment.systemPackages
```

## Phase 1: Create the consolidated feature

Create:
- `modules/features/dev/llm-agents.nix`

Implementation target:
- one `llm-agents` aspect
- HM package list built from available attrs in `host.llmAgentsPkgs`
- NixOS package list built from available attrs in `host.llmAgentsPkgs`

Preferred implementation pattern:
```nix
{ den, ... }:
{
  den.aspects.llm-agents = den.lib.parametric {
    includes = [
      ({ host, ... }: {
        nixos = { lib, ... }: {
          environment.systemPackages =
            lib.optional (host.llmAgentsPkgs ? openclaw) host.llmAgentsPkgs.openclaw;
        };

        homeManager = { lib, ... }: {
          home.packages =
            lib.optionals (host.llmAgentsPkgs ? claude-code) [ host.llmAgentsPkgs.claude-code ]
            ++ lib.optionals (host.llmAgentsPkgs ? codex) [ host.llmAgentsPkgs.codex ]
            ++ lib.optionals (host.llmAgentsPkgs ? crush) [ host.llmAgentsPkgs.crush ]
            ++ lib.optionals (host.llmAgentsPkgs ? kilocode-cli) [ host.llmAgentsPkgs.kilocode-cli ]
            ++ lib.optionals (host.llmAgentsPkgs ? opencode) [ host.llmAgentsPkgs.opencode ];
        };
      })
    ];
  };
}
```

## Phase 2: Replace host includes

Change:
- `predator`: replace all `ai-*` includes with `llm-agents`
- `aurelius`: replace `ai-openclaw` with `llm-agents`

Goal:
- host intent becomes simpler without changing actual package outcome

## Phase 3: Remove obsolete files

Delete:
- `modules/features/ai/ai-claude-code.nix`
- `modules/features/ai/ai-codex.nix`
- `modules/features/ai/ai-crush.nix`
- `modules/features/ai/ai-kilocode.nix`
- `modules/features/ai/ai-openclaw.nix`
- `modules/features/ai/ai-opencode.nix`

If the `ai/` folder becomes empty, remove the empty folder from git tracking.

## Phase 4: Docs and repo map cleanup

Update at least:
- `docs/for-agents/001-repo-map.md`
- `docs/for-agents/plans/012-feature-readability-refactor-plan.md`
- any docs that still mention `ai-*` as current live files

Likely wording update:
- AI is no longer its own feature folder
- LLM agent tooling now lives under `dev/llm-agents.nix`

## Validation Strategy

Mandatory after consolidation:
```bash
./scripts/check-docs-drift.sh
./scripts/run-validation-gates.sh structure
./scripts/run-validation-gates.sh predator
./scripts/run-validation-gates.sh aurelius
nix build .#nixosConfigurations.predator.config.system.build.toplevel -o /tmp/llm-agents-after-predator-system
nix build .#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path -o /tmp/llm-agents-after-predator-hm
nix store diff-closures /tmp/llm-agents-before-predator-system /tmp/llm-agents-after-predator-system
nix store diff-closures /tmp/llm-agents-before-predator-hm /tmp/llm-agents-after-predator-hm
```

Additional recommended checks:
```bash
nix eval --json .#nixosConfigurations.aurelius.config.environment.systemPackages
nix eval --json .#nixosConfigurations.predator.config.home-manager.users.higorprado.home.packages
```

Expected outcome:
- system diff: empty
- HM diff: empty

If diff is not empty:
- inspect whether `openclaw` leaked to `predator`
- inspect whether any user-level agents disappeared from `predator`

## Commit Strategy

Recommended commit boundaries:

1. `refactor: consolidate llm agents into one feature`
2. `docs: update llm agent layout references`

Or one commit if the diff remains compact and fully validated.

## Risks

1. `openclaw` may exist on more than one system.
   Mitigation:
   - verify package availability per host before relying on the simple availability-based rule

2. Host includes may become simpler while package selection changes silently.
   Mitigation:
   - use closure diffs and targeted `nix eval`

3. Docs may still reference the removed `ai/*` tree.
   Mitigation:
   - run `check-docs-drift.sh`
   - search for `ai-` references after the code change

## Success Criteria

- one tracked file owns the repo’s LLM agent surface
- host includes are simpler
- old `ai-*` files are gone
- `predator` still gets the same user-level agents
- `aurelius` still gets the same server-level agent
- closure diffs are empty
