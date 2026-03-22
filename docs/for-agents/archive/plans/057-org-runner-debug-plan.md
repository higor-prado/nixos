# Organization Runner Debug Plan

## Goal

Identify the exact failure mode preventing the Aurelius GitHub runner from registering at the `higor-prado` organization scope, without making further speculative runtime changes.

## Scope

In scope:
- inspect the tracked owner at [github-runner.nix](/home/higorprado/nixos/modules/features/system/github-runner.nix)
- inspect the effective runtime config and wrapper scripts generated for `github-runner-aurelius.service`
- reproduce the runner registration path manually on `aurelius`
- compare organization registration using:
  - direct PAT
  - freshly minted registration token
  - with and without `runnerGroup`
- determine whether the fault is in:
  - our owner usage
  - the NixOS module behavior
  - runner CLI invocation shape

Out of scope:
- adding more GitHub features
- introducing a second runner owner
- changing the intended org-level target
- documenting a final solution before the root cause is isolated

## Current State

- [github-runner.nix](/home/higorprado/nixos/modules/features/system/github-runner.nix) wires `services.github-runners.aurelius`
- private binding at `private/hosts/aurelius/services.nix` points to `https://github.com/higor-prado`
- `runnerGroup = "Default"` is currently set privately
- `nh os test path:$PWD#aurelius --target-host aurelius --build-host aurelius -e passwordless` fails on service activation
- `github-runner-aurelius.service` fails in `ExecStartPre` during configure
- the journal repeatedly shows:
  - `POST https://api.github.com/actions/runner-registration`
  - `404 Not Found`
- the PAT in `~/.config/github-runner/aurelius.token` can call:
  - `GET /orgs/higor-prado/actions/runners`
  - `POST /orgs/higor-prado/actions/runners/registration-token`

## Desired End State

- the exact failing layer is known, with proof
- we know whether org-level registration is blocked by:
  - the token type
  - the runner CLI
  - the generated arguments
  - the NixOS module assumptions
  - or the private binding content
- only after that, a corrective implementation plan can be written

## Phases

### Phase 0: Baseline

Targets:
- capture the current tracked owner and private binding state
- capture the exact generated config JSON and configure wrapper input

Validation:
- inspect:
  - [github-runner.nix](/home/higorprado/nixos/modules/features/system/github-runner.nix)
  - `private/hosts/aurelius/services.nix`
  - generated runner config JSON
  - systemd unit

Diff expectation:
- no tracked runtime change

Commit target:
- none

### Phase 1: Reproduce Outside The Wrapper

Targets:
- run the equivalent registration flow manually on `aurelius`
- remove the systemd/Nix wrapper as a source of ambiguity

Changes:
- no tracked file edits
- execute controlled manual tests on `aurelius` with:
  - current org URL
  - current PAT
  - fresh registration token
  - optional `--runnergroup Default`

Validation:
- capture the exact command and response for each variant
- determine which variant first reproduces the `404`

Diff expectation:
- no tracked diff

Commit target:
- none

### Phase 2: Compare With Module Expectations

Targets:
- compare manual success/failure with the NixOS module behavior

Changes:
- inspect upstream NixOS module behavior in:
  - `.../nixos/modules/services/continuous-integration/github-runner/options.nix`
  - `.../nixos/modules/services/continuous-integration/github-runner/service.nix`
- verify whether our owner must set:
  - `tokenType`
  - `runnerGroup = null`
  - a different URL form
  - a PAT-only flow

Validation:
- write down the first concrete divergence between:
  - manual invocation
  - generated invocation

Diff expectation:
- at most notes in the plan if needed

Commit target:
- none

### Phase 3: Minimal Corrective Slice

Targets:
- apply the smallest change that fixes the proven root cause

Changes:
- only the file(s) directly required by the isolated cause

Validation:
- `nh os test path:$PWD#aurelius --target-host aurelius --build-host aurelius -e passwordless`
- `ssh aurelius 'systemctl status github-runner-aurelius.service --no-pager -l'`
- `ssh aurelius 'journalctl -u github-runner-aurelius.service --no-pager -n 120'`
- confirm runner appears at org scope

Diff expectation:
- narrow diff in owner/private binding only

Commit target:
- `fix(ci): correct org-level aurelius runner registration`

## Risks

- stale runner entries in GitHub UI may confuse interpretation after repeated reconfiguration
- one-hour registration tokens can expire during slow debugging loops
- mixing PAT and registration token in the same file can invalidate conclusions
- changing multiple inputs at once would make the result useless

## Definition of Done

- the exact cause of the organization registration failure is isolated with evidence
- the fix, if any, is minimal and directly tied to that cause
- `github-runner-aurelius.service` starts successfully against the org scope
- the runner appears in `higor-prado` organization runners
- no additional speculative feature work is mixed into the debugging slice
