# Forgejo Predator Access Plan

## Goal

Add Forgejo back to `aurelius` only when it has a real, validated access path
from `predator`. The slice must stay narrow, repo-native, and proof-based: no
local-only false completion, no host-owner drift, and no exposure model that is
broader than the intended Tailscale consumer path.

## Scope

In scope:
- a dedicated Forgejo feature owner in `modules/features/system/`
- `aurelius` host composition for the Forgejo slice
- an explicit Tailscale-based access model from `predator`
- matching runtime semantics:
  - listener
  - firewall
  - `DOMAIN`
  - `ROOT_URL`
- predator-side validation of the real URL
- operator docs only if the path is actually validated

Out of scope:
- backup/restic
- reverse proxy, Caddy, or Tailscale Serve unless a concrete limitation appears
- Git SSH exposure
- mirror automation
- Actions runner integration

## Current State

- Forgejo was removed from active runtime because the previous slice only proved
  local host health and never proved the actual consumer path from `predator`.
- `aurelius` already has:
  - `nixos.tailscale`
  - `nixos.docker`
  - `nixos.mosh`
  - `nixos.node-exporter`
- `predator` and `aurelius` are both present in the same tailnet.
- The real Tailscale DNS name observed on `aurelius` is:
  - `aurelius.your-tailnet.ts.net`
- The Tailscale IP observed on `aurelius` is:
  - `100.x.x.x`
- The current healthy reference for host-owner readability remains
  [predator.nix](/home/higorprado/nixos/modules/hosts/predator.nix).

## Desired End State

- Forgejo is reintroduced as a narrow feature owner.
- `aurelius` composes that owner cleanly, without inline module payloads or
  secret-dependent tracked hacks.
- Forgejo is reachable from `predator` via the explicit Tailscale consumer URL.
- `ROOT_URL`, bind semantics, firewall rules, and docs all agree on that exact
  URL.
- The slice is only marked complete after `predator` successfully reaches the
  real Forgejo endpoint.

## Phases

### Phase 0: Access Model Freeze

Targets:
- [modules/features/system/tailscale.nix](/home/higorprado/nixos/modules/features/system/tailscale.nix)
- [modules/hosts/aurelius.nix](/home/higorprado/nixos/modules/hosts/aurelius.nix)

Changes:
- freeze the access model as:
  - consumer host: `predator`
  - transport: Tailscale
  - URL: `http://aurelius.your-tailnet.ts.net:3000/`
- reject broader exposure for this slice:
  - no public firewall opening
  - no generic reverse proxy
  - no “local-only but counted as done”

Validation:
- inspect current Tailscale host facts on `aurelius`
- verify that the chosen URL matches the actual tailnet host identity

Diff expectation:
- plan-only explicit access contract

Commit target:
- `docs(forgejo): freeze predator access model`

### Phase 1: Reintroduce Narrow Forgejo Owner

Targets:
- [modules/features/system/forgejo.nix](/home/higorprado/nixos/modules/features/system/forgejo.nix)
- [modules/hosts/aurelius.nix](/home/higorprado/nixos/modules/hosts/aurelius.nix)

Changes:
- add a narrow `nixos.forgejo` owner back to the repo
- keep service behavior owned by the feature:
  - enable Forgejo
  - port `3000`
  - private instance defaults
  - SSH disabled
  - registration disabled
- keep host-specific concrete state in `aurelius.nix`:
  - `DOMAIN = "aurelius.your-tailnet.ts.net"`
  - `ROOT_URL = "http://aurelius.your-tailnet.ts.net:3000/"`
  - firewall opening restricted to `tailscale0`
- avoid binding to `127.0.0.1` if the slice claims predator access
- avoid binding to a transient Tailscale IP if `0.0.0.0` plus interface-scoped
  firewall rule is cleaner and more robust at boot

Validation:
- `./scripts/run-validation-gates.sh structure`
- `nix eval --raw path:$PWD#nixosConfigurations.aurelius.config.services.forgejo.settings.server.ROOT_URL`
- `nix build --no-link path:$PWD#nixosConfigurations.aurelius.config.system.build.toplevel`

Diff expectation:
- Forgejo returns as a repo-native service slice with coherent access semantics

Commit target:
- `feat(forgejo): add aurelius tailscale-only service`

### Phase 2: Real Host Validation

Targets:
- live `aurelius` runtime
- real consumer path from `predator`

Changes:
- apply the slice on `aurelius`
- verify both host-side and predator-side behavior

Validation:
- `nh os test path:$PWD#aurelius --target-host aurelius --build-host aurelius -e passwordless`
- `ssh aurelius 'systemctl is-active forgejo.service'`
- `ssh aurelius 'ss -lnt | rg ":3000 "'`
- `ssh aurelius 'curl -I --max-time 5 http://127.0.0.1:3000 | sed -n "1,5p"'`
- from `predator`, verify:
  - name resolution or direct curl against `http://aurelius.your-tailnet.ts.net:3000/`
  - response headers from the real URL

Diff expectation:
- the slice is proved from both the host and the intended consumer path

Commit target:
- `test(forgejo): prove predator tailscale access`

### Phase 3: Operator Docs

Targets:
- [docs/for-humans/workflows/106-deploy-aurelius.md](/home/higorprado/nixos/docs/for-humans/workflows/106-deploy-aurelius.md)
- possibly [docs/for-agents/current/050-aurelius-next-steps-dendritic-plan-progress.md](/home/higorprado/nixos/docs/for-agents/current/050-aurelius-next-steps-dendritic-plan-progress.md)

Changes:
- document the Forgejo access path only if Phase 2 actually proves it
- record the slice in the `050` progress log with the correct proof boundary
- do not add docs for unproved alternate URLs

Validation:
- `./scripts/check-docs-drift.sh`
- `./scripts/check-repo-public-safety.sh`

Diff expectation:
- docs describe the exact proven URL and nothing broader

Commit target:
- `docs(forgejo): document predator access path`

## Risks

- Binding too narrowly to a Tailscale IP could make startup brittle if the
  address is not present yet when Forgejo starts.
- Opening a global firewall port would violate the intended Tailscale-only
  exposure model.
- Counting local host health as completion would recreate the same failure this
  plan exists to prevent.

## Definition of Done

- Forgejo exists again as a narrow tracked feature owner.
- `aurelius` imports Forgejo cleanly, without host-owner drift.
- `ROOT_URL`, listener, and firewall rules all match the exact Tailscale URL
  used by the real consumer host.
- The real URL responds from `predator`, not only from `aurelius`.
- Human docs mention Forgejo only if that predator-side URL was actually
  validated.
