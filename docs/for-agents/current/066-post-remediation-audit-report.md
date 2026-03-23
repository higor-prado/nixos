# Post-Remediation Audit Report

Date: 2026-03-23

Scope:
- Reviewed the full worktree after audit-064 remediation changes.
- Inspected all live private files and compared with tracked `.example` counterparts.
- Checked tracked files for leaked private information.
- Verified WireGuard setup (client on predator, server on aurelius).
- Checked dendritic pattern compliance.
- Ran structural/public-safety/eval validation gates.

## Critical: WireGuard client breakage introduced and reverted

The audit-064 remediation added `networking.wg-quick.interfaces.*` declarations to
`private/hosts/predator/networking.nix`. This broke the existing VPN because:

- WireGuard on `predator` was already managed by **NetworkManager**, not wg-quick.
- NM connections `wg-br` and `wg-us` were created via `nmcli connection import` from
  `~/.config/wireguard/{wg-br,wg-us}.conf`.
- NM connections are persisted in `/etc/NetworkManager/system-connections/` (already in
  `persisted-paths.nix`).
- The `networking.wg-quick.interfaces.*` declarations created conflicting systemd services
  (`wg-quick-wg-br.service`, `wg-quick-wg-us.service`) that interfered with NM's own
  WireGuard handling.

Resolution: removed the wg-quick declarations and reverted persisted-paths.
VPN verified working again via `nmcli connection up wg-br` with egress through aurelius.

Lesson: before adding declarative bindings for an existing service, verify which
subsystem currently owns it (NetworkManager vs wg-quick vs systemd).

## Findings

### 1. High: Tailscale domain hardcoded in tracked feature modules

Evidence:
- `modules/features/system/grafana.nix:28-29`: `aurelius.your-tailnet.ts.net`
- `modules/features/system/forgejo.nix:14-15`: `aurelius.your-tailnet.ts.net`
- `modules/hosts/predator.nix:40`: `aurelius.your-tailnet.ts.net` in mosh abbr

Impact:
- Goal 4 (security): exposes internal Tailnet name (`your-tailnet`) and host topology.
  The public-safety gate does not catch domain names, only IPs/emails/tokens.
- Goal 2 (dendritic): these are deployment-specific endpoints that belong in private
  overrides, not tracked feature modules. The feature owners should use a generic shape
  and let the private layer inject the concrete domain.

### 2. Medium: predator services.nix.example is stale

Evidence:
- Live `private/hosts/predator/services.nix` contains:
  - Attic publisher config (endpoint, cache, token file path)
  - Attic client substituter config
  - `programs.nh.flake` setting
- `private/hosts/predator/services.nix.example` only shows commented Attic templates,
  missing `programs.nh.flake`.

Impact:
- Goal 1 (reproducibility): if reconstructing from examples, the nh flake path would
  be missing, and the Attic substituter config shape would need guessing.

### 3. Medium: predator networking.nix.example does not reflect mDNS resolver

Evidence:
- Live `private/hosts/predator/networking.nix` contains a full mDNS DNS resolver
  setup (systemd service + timer for resolving `cerebelo.local`).
- `private/hosts/predator/networking.nix.example` only mentions NM-managed VPN and
  placeholder DNS line.

Impact:
- Goal 1 (reproducibility): the mDNS resolver shape is non-trivial and would be lost
  after a wipe if only the example is available.

### 4. Medium: aurelius services.nix.example is stale

Evidence:
- Live `private/hosts/aurelius/services.nix` has active GitHub runner config
  (url, tokenFile, runnerGroup).
- `private/hosts/aurelius/services.nix.example` has only a commented-out template
  with placeholder values.

Impact:
- Goal 1 (reproducibility): example doesn't reflect the active runner wiring shape.

### 5. Highest (Regression): IPv6 leak when VPN is active via NetworkManager

Evidence:
- NM's wg-br connection has `ipv6.method: disabled` (disables IPv6 on the tunnel
  interface only).
- Unlike the old wg-quick PostUp (`sysctl -w net.ipv6.conf.all.disable_ipv6=1`), NM
  does **not** disable IPv6 globally.
- `curl ifconfig.me` returns an IPv6 address from the local ISP even when wg-br is
  active, bypassing the VPN entirely (browsers use happy eyeballs / RFC 6724).

Impact:
- Goal 3 (functional): VPN is not providing full tunnel protection. IPv6 traffic
  leaks outside the tunnel. The user's browser will use IPv6 by default when available.

Possible fixes:
- NM dispatcher script to set `net.ipv6.conf.all.disable_ipv6=1` on connection up
  and revert on down.
- Or set `ipv6.method: disabled` globally on the physical interface when VPN is active.
- Or add `::/0` to the wg-br AllowedIPs and route IPv6 through the tunnel (requires
  aurelius to support IPv6 forwarding).

### 6. Low: aurelius default.nix.example sudo shape diverges from live

Evidence:
- Live `private/hosts/aurelius/default.nix` has active (non-commented) sudo rules and
  does NOT set `users.mutableUsers`.
- Example has commented sudo rules and sets `users.mutableUsers = lib.mkForce false`.
- Example uses `{ lib, ... }:`, live uses `{ config, ... }:`.

Impact:
- Minor reproducibility gap. The shape is close enough to reconstruct, but the
  example suggests `mutableUsers` which the live config does not use.

## Verified

- Public-safety gate: PASS
  `./scripts/check-repo-public-safety.sh`

- Structural validation: PASS
  `./scripts/run-validation-gates.sh structure`

- Eval checks:
  - `nix eval --raw path:$PWD#nixosConfigurations.predator.config.system.build.toplevel.drvPath` — PASS
  - `nix eval --raw path:$PWD#nixosConfigurations.aurelius.config.system.build.toplevel.drvPath` — PASS

- Dendritic pattern compliance in recent changes:
  - `modules/desktops/{dms-on-niri,niri-standalone}.nix` correctly own greetd session decisions
  - `modules/features/desktop/niri.nix` no longer carries synthetic `custom.niri.standaloneSession`
  - `modules/features/system/networking-wireguard-server.nix` is narrow (infra only, no custom options)
  - `modules/features/system/networking-wireguard-client.nix` is narrow (tooling + reverse path)
  - No `mkIf`/`mkOption` anti-patterns in recent changes
  - No `specialArgs` usage

- Private file safety:
  - No private keys in tracked files
  - No real IP addresses in tracked files (except Tailscale domain — Finding 1)
  - SSH keys, WireGuard keys, tokens all properly in untracked private files
  - `.config/wireguard/{wg-br,wg-us}.conf` contain private keys but are user-local, not git-tracked

- Example files synced in this session:
  - `predator/default.nix.example` — now matches live (includes `./auth.nix`)
  - `aurelius/default.nix.example` — now matches live shape (imports networking + services)

## Summary of open items

| # | Severity | Finding | Goal |
|---|----------|---------|------|
| 1 | High | Tailscale domain hardcoded in tracked feature modules | 2, 4 |
| 2 | Medium | predator services.nix.example stale (missing nh.flake, full Attic shape) | 1 |
| 3 | Medium | predator networking.nix.example missing mDNS resolver shape | 1 |
| 4 | Medium | aurelius services.nix.example stale (runner shape not shown) | 1 |
| 5 | Highest | IPv6 leak when NM VPN is active (regression) | 3 |
| 6 | Low | aurelius default.nix.example minor sudo/mutableUsers divergence | 1 |
