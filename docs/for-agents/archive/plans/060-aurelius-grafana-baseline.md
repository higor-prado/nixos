# Aurelius Grafana Baseline Plan

## Goal

Add a narrow Grafana owner on `aurelius` that is actually usable from
`predator` over Tailscale, without pushing secrets or auth glue into tracked
runtime.

## Scope

In scope:
- add a narrow `grafana.nix` owner under `modules/features/system/`
- keep Grafana service semantics inside the owner
- expose Grafana only on `tailscale0`
- provision the local Prometheus datasource declaratively
- use a file-provider secret key instead of tracking any Grafana credential
- prove host health on `aurelius`
- prove consumer reachability from `predator`
- update the `050` roadmap only after runtime proof

Out of scope:
- dashboards beyond the baseline datasource wiring
- SSO or private admin credentials
- public internet exposure
- alerting/contact points

## Current State

- `aurelius` already serves:
  - node-exporter on `127.0.0.1:9100`
  - Prometheus on `0.0.0.0:9090` over Tailscale
- there is no tracked Grafana owner yet
- Phase 5 of
  [050-aurelius-next-steps-dendritic-plan.md](/home/higorprado/nixos/docs/for-agents/plans/050-aurelius-next-steps-dendritic-plan.md)
  explicitly leaves Grafana as the next observability follow-up

## Desired End State

- `aurelius` composes one narrow `nixos.grafana` owner
- Grafana listens on a dedicated Tailscale-only port
- Grafana is remotely reachable from `predator`
- the Prometheus datasource is provisioned declaratively
- no admin credential or private override is required for this baseline
- Grafana's mandatory `secret_key` comes from a local file-provider path on the
  host runtime, not from tracked config

## Phases

### Phase 0: Owner

Targets:
- [modules/features/system/grafana.nix](/home/higorprado/nixos/modules/features/system/grafana.nix)
- [modules/hosts/aurelius.nix](/home/higorprado/nixos/modules/hosts/aurelius.nix)

Changes:
- add a narrow Grafana owner
- keep firewall, bind, root URL, and datasource provisioning in the owner
- wire `aurelius` to compose `nixos.grafana`

Validation:
- `./scripts/run-validation-gates.sh structure`
- `nix eval --raw path:$PWD#nixosConfigurations.aurelius.config.system.build.toplevel.drvPath`

Commit target:
- `feat(monitoring): add aurelius grafana baseline`

### Phase 1: Runtime Proof

Targets:
- the new Grafana owner
- [050-aurelius-next-steps-dendritic-plan-progress.md](/home/higorprado/nixos/docs/for-agents/current/050-aurelius-next-steps-dendritic-plan-progress.md)

Changes:
- deploy the owner to `aurelius`
- prove local service health
- prove Tailscale reachability from `predator`
- record the slice honestly in the roadmap

Validation:
- `./scripts/run-validation-gates.sh all`
- `./scripts/check-docs-drift.sh`
- `./scripts/check-repo-public-safety.sh`
- `nh os test path:$PWD#aurelius --target-host aurelius --build-host aurelius -e passwordless`
- on `aurelius`:
  - `systemctl status grafana.service --no-pager -l`
  - `curl -I http://127.0.0.1:3001/`
- from `predator`:
  - `curl -I http://aurelius.your-tailnet.ts.net:3001/`

## Definition of Done

- `aurelius` composes one narrow Grafana owner cleanly
- Grafana is healthy on the host
- Grafana is reachable from `predator` over Tailscale
- Prometheus is provisioned as the default datasource
- docs match the real access path
