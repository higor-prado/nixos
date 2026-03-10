# Semantic Host Selection Progress

Date: 2026-03-10
Status: completed

Plan:
- `docs/for-agents/plans/014-semantic-host-selection-plan.md`

## Goal

Make `llm-agents` den-native and pretty by moving host policy into host data,
then keep a shortlist of other candidate features where the same pattern may
improve readability.

## Candidate Priority

- `P0`: `llm-agents`
- `P1`: `niri`
- `P2`: `gui-apps`, `theme-zen`, `dms-wallpaper`, `music-client`

## Notes

- The current `llm-agents` implementation is correct but not ideal because it
  branches on `host.name`.
- Repo audit found that not every raw `host.inputs` / `host.customPkgs` use is
  a problem; only the cases where the host should really own semantic choice
  are candidates for this pattern.
- Current execution target:
  - replace public `llmAgentsPkgs` host context with semantic `llmAgents`
  - keep `llmAgentsPkgs` local to host files only as a helper for building selections
  - make `llm-agents` a pure consumer via `den.lib.parametric.exactly`
- Result:
  - `llm-agents` now consumes `host.llmAgents.homePackages` and `host.llmAgents.systemPackages`
  - `predator` and `aurelius` own the selection policy in their host files
  - new-host skeleton templates/fixtures and desktop composition simulations were updated to the new contract
  - living docs now describe semantic host selection as the preferred den-native pattern when host policy matters
- Validation:
  - `./scripts/check-docs-drift.sh`
  - `bash scripts/check-changed-files-quality.sh`
  - `bash tests/scripts/new-host-skeleton-fixture-test.sh`
  - `./scripts/run-validation-gates.sh structure`
  - `./scripts/run-validation-gates.sh aurelius`
  - `nix build path:$PWD#nixosConfigurations.predator.config.system.build.toplevel -o /tmp/semantic-host-before-predator-system`
  - `nix build path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path -o /tmp/semantic-host-before-predator-hm`
  - `nix build path:$PWD#nixosConfigurations.predator.config.system.build.toplevel -o /tmp/semantic-host-after-predator-system`
  - `nix build path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path -o /tmp/semantic-host-after-predator-hm`
  - `nix store diff-closures /tmp/semantic-host-before-predator-system /tmp/semantic-host-after-predator-system`
  - `nix store diff-closures /tmp/semantic-host-before-predator-hm /tmp/semantic-host-after-predator-hm`
- Diff result:
  - predator system diff: empty
  - predator HM diff: empty
