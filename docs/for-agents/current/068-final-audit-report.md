# Final Audit Report

Date: 2026-03-23

Scope:
- Followed the same 4 goals from the original audit instructions given to the prior agent.
- Read all tracked feature modules, host compositions, hardware config, private files, and example files.
- Ran all validation gates and eval checks.
- Compared all live private files against tracked `.example` counterparts.
- Verified dendritic pattern compliance across all feature modules.
- Checked all tracked files for leaked private information (domains, IPs, keys, tokens).

## Goals

1. **Reproducibility**: can the environment be reproduced after a wipe/rebuild?
2. **Dendritic compliance**: does the repo follow the dendritic pattern?
3. **Functionality**: is everything configured actually functional?
4. **Security**: is private information absent from tracked files?

## Validation Gates

| Gate | Result |
|------|--------|
| `./scripts/check-repo-public-safety.sh` | PASS |
| `./scripts/run-validation-gates.sh structure` | PASS |
| `nix eval ... predator ... toplevel.drvPath` | PASS |
| `nix eval ... aurelius ... toplevel.drvPath` | PASS |

## Status of Previous Findings

### Report 064 findings — all CLOSED

| # | Finding | Status |
|---|---------|--------|
| 1 | No WireGuard client binding on predator | CLOSED — by design: tunnels are NM-managed, not wg-quick. `networking-wireguard-client` provides infra (tooling, loose reverse path, IPv6 leak fix). NM connections persisted via `/etc/NetworkManager/system-connections/`. Example file documents this. |
| 2 | Public-safety gate fails on RFC1918 IPs in examples | CLOSED — allowlist entries added in `scripts/public-safety-allowlist.txt`. Gate passes. |
| 3 | Undeclared WireGuard confs in persisted-paths | CLOSED — `/etc/wireguard/*.conf` removed from `hardware/predator/persisted-paths.nix`. NM owns VPN state persistence. |
| 4 | Stale `.example` files | CLOSED — all example files updated to match live shapes. |

### Report 066 findings — all CLOSED

| # | Finding | Status |
|---|---------|--------|
| 1 | Tailscale domain hardcoded in tracked modules | CLOSED — `grafana.nix`, `forgejo.nix` no longer contain domain values. `predator.nix` no longer contains `amdev` mosh abbreviation. All moved to private overrides. `grep -r "your-tailnet" modules/` returns nothing. |
| 2 | predator `services.nix.example` stale | CLOSED — now shows Attic publisher, substituter, `nh.flake`, and `amdev` abbreviation shapes. |
| 3 | predator `networking.nix.example` missing mDNS shape | CLOSED — now shows full mDNS resolver service/timer template. |
| 4 | aurelius `services.nix.example` stale | CLOSED — now shows GitHub runner + Grafana/Forgejo domain shapes. |
| 5 | IPv6 leak when NM VPN is active (regression) | CLOSED — `networking-wireguard-client.nix` now includes an NM dispatcher script that sets `net.ipv6.conf.all.disable_ipv6=1` on `wg-*` interface up and reverts on down. |
| 6 | aurelius `default.nix.example` sudo/mutableUsers divergence | CLOSED — example now matches live shape (active sudo rules, no `mutableUsers`, uses `{ config, ... }:`). |

## New Findings

### None critical or high.

### 1. Info: historical agent docs contain Tailscale domain

Evidence:
- `docs/for-agents/plans/067-audit-066-remediation.md` references `aurelius.your-tailnet.ts.net` (describes what was found before remediation).
- `docs/for-agents/current/066-post-remediation-audit-report.md` references the same domain (describes the finding).
- Various `docs/for-agents/archive/` files contain historical references.

Assessment:
- These are historical records describing what was found and fixed. They are not configuration files and do not affect builds.
- The public-safety gate does not check for domain names (by design — it checks IPs, emails, tokens).
- No action required unless the repo policy changes to also redact domains from historical docs.

### 2. Info: aurelius `default.nix.example` uses `ssh-ed25519` placeholder while live uses `ssh-rsa`

Evidence:
- `private/hosts/aurelius/default.nix.example:12` shows `ssh-ed25519 AAAA...` as placeholder.
- Live file uses an `ssh-rsa` key.

Assessment:
- The example correctly shows the shape (`users.users.${userName}.openssh.authorizedKeys.keys`). The key type is a deployment decision.
- No action required. If the live key is ever rotated to ed25519, the example already matches. The structural shape is identical.

## Dendritic Compliance

Verified across all files in `modules/features/`:

- No `mkIf` usage for feature toggling.
- No `mkOption` for custom option surfaces.
- No `specialArgs` usage.
- No `mkMerge` on shared module lists.
- Features publish under `flake.modules.nixos.*` and `flake.modules.homeManager.*`.
- Import is the decision — compositions in `modules/hosts/{predator,aurelius}.nix` explicitly list features.
- Private overrides use direct lower-level NixOS options (`services.grafana.settings.server`, `networking.wg-quick.interfaces.*`, etc.), not synthetic option surfaces.

The `networking-wireguard-client.nix` and `networking-wireguard-server.nix` modules are narrow feature owners: they declare infra (tooling, sysctls, firewall policy, dispatcher scripts) and leave concrete keys/addresses/peers to private overrides.

## Reproducibility

For each host, the tracked code + private overrides + example shapes are sufficient to reconstruct the environment:

**aurelius**:
- Tracked: host composition, all feature modules, hardware config, disko layout.
- Private (gitignored): `default.nix` (SSH key, sudo rules), `networking.nix` (WireGuard server binding), `services.nix` (GitHub runner, Grafana/Forgejo domains).
- Example files match live shapes for all three private files.
- Token/key files documented in `docs/for-humans/workflows/107-aurelius-service-bootstrap.md`.

**predator**:
- Tracked: host composition, all feature modules, hardware config, impermanence/persisted-paths.
- Private (gitignored): `default.nix` (imports), `auth.nix` (SSH key), `networking.nix` (mDNS resolver), `services.nix` (Attic, nh, amdev), `hardware-local.nix`.
- Example files match live shapes for `default.nix`, `networking.nix`, `services.nix`.
- WireGuard VPN: NM-managed, connections persisted via `/etc/NetworkManager/system-connections/`, source configs at `~/.config/wireguard/`. Documented in `networking.nix.example` and bootstrap doc.

## Functionality

- Both hosts evaluate cleanly (no eval errors).
- IPv6 leak prevention is in place via NM dispatcher script in `networking-wireguard-client.nix`.
- Grafana and Forgejo feature modules are domain-agnostic; concrete domains injected via private overrides.
- `adev` abbreviation in tracked `predator.nix` uses plain `aurelius` hostname (resolves via SSH config, no domain exposure).
- All structural validation gates pass (14 checks).

## Security

- No Tailscale domains in tracked module files (`grep -r "your-tailnet" modules/` — zero matches).
- No private IPs in tracked files (public-safety gate passes).
- No private keys, tokens, or credentials in tracked files.
- SSH keys, WireGuard keys, and service tokens all reside in untracked private files or on-host paths.
- Example files use placeholder values (`your-user`, `your-tailnet`, `replace-with-real-key`).

## Summary

All findings from reports 064 and 066 are resolved. No new critical, high, or medium findings. The repo is clean against all 4 audit goals. Two informational items noted (historical domain references in agent docs, key type mismatch in example) — neither requires action.
