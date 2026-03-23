# Aurelius GitHub Runner Progress

## Status

Complete

## Related Plan

- [056-aurelius-github-runner.md](/home/higorprado/nixos/docs/for-agents/plans/056-aurelius-github-runner.md)

## Baseline

- Active branch: `aurelius-next-steps-plan`
- Pre-existing unrelated worktree dirt remained outside this slice:
  - [flake.lock](/home/higorprado/nixos/flake.lock)
  - [llm-agents.nix](/home/higorprado/nixos/modules/features/dev/llm-agents.nix)
  - [predator.nix](/home/higorprado/nixos/modules/hosts/predator.nix)
- There was no tracked GitHub runner owner before this slice.

## Slices

### Slice 1

- Added a narrow owner:
  - [github-runner.nix](/home/higorprado/nixos/modules/features/system/github-runner.nix)
- Kept host composition clean:
  - [aurelius.nix](/home/higorprado/nixos/modules/hosts/aurelius.nix) now composes `nixos.github-runner`
- Added tracked example shape for host-private runner binding:
  - [services.nix.example](/home/higorprado/nixos/private/hosts/aurelius/services.nix.example)
  - [default.nix.example](/home/higorprado/nixos/private/hosts/aurelius/default.nix.example)
- The owner now owns:
  - `services.github-runners.aurelius`
  - runner labels
  - explicit work directory
  - docker-capable service wiring
- Private binding remains outside tracked runtime:
  - `services.github-runners.aurelius.url`
  - `services.github-runners.aurelius.tokenFile`
  - `services.github-runners.aurelius.runnerGroup`
- Validation:
  - `./scripts/run-validation-gates.sh structure` passed
  - `nix eval --raw path:$PWD#nixosConfigurations.aurelius.config.system.build.toplevel.drvPath` passed
  - `nix eval --json path:$PWD#nixosConfigurations.aurelius.config.services.github-runners` returned `{}`
  - a synthetic `extendModules` eval with a fake private binding initially
    exposed a real owner bug:
    - the first cut incorrectly depended on `config.username` inside the
      lower-level NixOS runner owner
  - the owner was corrected to use a dedicated system user `github-runner`
  - the same synthetic eval then returned a coherent
    `services.github-runners.aurelius` config with:
    - `enable = true`
    - `user = "github-runner"`
    - `workDir = "/var/lib/github-runner-aurelius/work"`
- Classification:
  - the tracked owner shape is correct and evaluates cleanly
  - the slice is still partial because the private Aurelius runner binding is not present in evaluated runtime, so no local service proof exists yet

## Final State

- The repo now has a narrow tracked GitHub runner owner for `aurelius`.
- The host owner stayed clean.
- No token or repository binding was tracked.
- A real private binding now exists in the gitignored Aurelius override.
- Real host deployment was attempted with:
  - `nh os test path:$PWD#aurelius --target-host aurelius --build-host aurelius -e passwordless`
- After the token file was created on the host, the same deployment command passed.
- Real host proof now shows:
  - `github-runner` system user exists
  - `/var/lib/github-runner-aurelius` and `/var/lib/github-runner-aurelius/work` exist with the correct ownership
  - `github-runner-aurelius.service` is `active (running)`
  - the configure step logged:
    - `Connected to GitHub`
    - `Runner successfully added`
    - `Listening for Jobs`
- The binding was later migrated from repo scope to org scope:
  - `url = "https://github.com/higor-prado"`
  - `runnerGroup = "Default"`
- Org-level runtime proof now also exists:
  - the runner is online in `higor-prado`
  - the proven workflow shape for org jobs is:
    - `runs-on.group = "Default"`
    - labels `self-hosted`, `aurelius`, `nixos`, `aarch64`
- Workflow-job execution proof is complete:
  - `higor-prado/nixos` runner smoke succeeded
  - `higor-prado/keyrs` runner smoke succeeded
- Honest classification:
  - tracked owner proof is complete
  - local runtime proof is complete
  - GitHub-side registration proof is complete
  - workflow-job execution proof is complete
