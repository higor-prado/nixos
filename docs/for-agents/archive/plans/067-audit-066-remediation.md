# Audit 066 Remediation

## Goal

Close all findings from the post-remediation audit
(`docs/for-agents/current/066-post-remediation-audit-report.md`):
fix the IPv6 regression, move deployment-specific Tailscale domain out of
tracked modules, and sync remaining stale `.example` files.

## Scope

In scope:
- fix IPv6 leak when NM-managed WireGuard VPN is active (regression)
- move Tailscale domain from tracked feature modules to private overrides
- sync stale `.example` files with live private counterparts
- update predator networking example to reflect NM-managed VPN and mDNS resolver

Out of scope:
- changes to WireGuard server on aurelius
- changes to NM connection profiles themselves
- Tailscale configuration changes

## Dendritic Pattern Constraints

1. **No `mkOption` for feature toggling.** Import is the decision.
2. **`mkIf` only for actual NixOS option value checks** (e.g. `lib.mkIf config.networking.networkmanager.enable`).
3. **Deployment-specific values belong in private overrides**, not tracked feature modules.
4. **Feature owners stay narrow.** Generic behavior in tracked code, concrete deployment facts in gitignored overrides.
5. **No `specialArgs`.** Values flow via `config.*`.

## Current State

- WireGuard VPN on predator is managed by NetworkManager (not wg-quick)
- NM does not disable IPv6 globally when wg-br activates — IPv6 traffic bypasses VPN
- Before the audit-064 remediation, `/etc/wireguard/wg-br.conf` had `PostUp = sysctl -w net.ipv6.conf.all.disable_ipv6=1` which wg-quick would execute — that mechanism was removed
- `aurelius.your-tailnet.ts.net` hardcoded in `grafana.nix:28-29`, `forgejo.nix:14-15`, `predator.nix:40`
- `predator/services.nix.example`, `predator/networking.nix.example`, `aurelius/services.nix.example` are stale

## Desired End State

- IPv6 disabled globally when any WireGuard NM connection activates, re-enabled on down
- No Tailscale domain in tracked files (except archive docs)
- Feature modules for grafana/forgejo use generic shapes; private override injects domain
- All `.example` files reflect live private shapes
- All validation gates pass

## Phases

### Phase 0: Baseline

Validation:
- `./scripts/check-repo-public-safety.sh` — expected PASS
- `./scripts/run-validation-gates.sh structure` — expected PASS
- predator eval — expected PASS
- aurelius eval — expected PASS

### Phase 1: Fix IPv6 leak (Regression — Highest)

Targets:
- `modules/features/system/networking-wireguard-client.nix`

Changes:
- Add NM dispatcher script that:
  - On `$CONNECTION_TYPE == "wireguard"` and `$2 == "up"`: `sysctl -w net.ipv4.conf.all.disable_ipv6=1`
  - On `$CONNECTION_TYPE == "wireguard"` and `$2 == "down"`: `sysctl -w net.ipv6.conf.all.disable_ipv6=0`
- Guard with `lib.mkIf config.networking.networkmanager.enable` (valid per rules: actual NixOS option check)
- Use absolute store path for sysctl (`${pkgs.procps}/bin/sysctl`) to avoid PATH issues in dispatcher context

Shape:
```nix
networking.networkmanager.dispatcherScripts = lib.mkIf config.networking.networkmanager.enable [
  {
    source = pkgs.writeShellScript "wireguard-ipv6-toggle" ''
      if [ "$CONNECTION_TYPE" = "wireguard" ]; then
        case "$2" in
          up)   ${pkgs.procps}/bin/sysctl -qw net.ipv6.conf.all.disable_ipv6=1 ;;
          down) ${pkgs.procps}/bin/sysctl -qw net.ipv6.conf.all.disable_ipv6=0 ;;
        esac
      fi
    '';
    type = "basic";
  }
];
```

Validation:
- predator eval — must PASS
- `./scripts/run-validation-gates.sh structure` — must PASS
- Runtime: `nmcli connection up wg-br && curl ifconfig.me` should NOT return an IPv6 address
- Runtime: `sysctl net.ipv6.conf.all.disable_ipv6` should be `1` while VPN is active

Diff expectation:
- `modules/features/system/networking-wireguard-client.nix` only

Commit target:
- `fix(networking): disable ipv6 globally when wireguard vpn is active via nm`

### Phase 2: Move Tailscale domain to private overrides (High)

Targets:
- `modules/features/system/grafana.nix`
- `modules/features/system/forgejo.nix`
- `modules/hosts/predator.nix`
- `private/hosts/aurelius/services.nix`

Changes:

**grafana.nix**: Remove `domain` and `root_url` from tracked config. The feature enables
Grafana with generic settings; the concrete domain is injected by private override.

**forgejo.nix**: Same treatment — remove `DOMAIN` and `ROOT_URL`.

**aurelius services.nix (private)**: Add the domain values:
```nix
services.grafana.settings.server = {
  domain = "aurelius.your-tailnet.ts.net";
  root_url = "http://aurelius.your-tailnet.ts.net:3001/";
};
services.forgejo.settings.server = {
  DOMAIN = "aurelius.your-tailnet.ts.net";
  ROOT_URL = "http://aurelius.your-tailnet.ts.net:3000/";
};
```

**predator.nix**: Remove the `amdev` abbreviation that hardcodes the Tailscale domain.
Move it to `private/hosts/predator/services.nix` as a fish abbreviation set via
`programs.fish.shellAbbrs.amdev`.

Note: the host composition owns operator abbrs, but the Tailscale domain is a
deployment fact. Moving only the abbrs that contain the domain keeps tracked code clean.

Validation:
- predator eval — must PASS
- aurelius eval — must PASS
- `./scripts/check-repo-public-safety.sh` — must PASS
- `./scripts/run-validation-gates.sh structure` — must PASS
- Verify domain no longer in tracked modules: `grep -r "your-tailnet" modules/`
  should return nothing

Diff expectation:
- `grafana.nix`, `forgejo.nix`, `predator.nix` lose hardcoded domain
- `private/hosts/aurelius/services.nix` gains domain values (not tracked)
- `private/hosts/predator/services.nix` gains `amdev` abbr (not tracked)

Commit target:
- `refactor(services): move tailscale domain to private overrides`

### Phase 3: Sync stale .example files (Medium)

Targets:
- `private/hosts/predator/services.nix.example`
- `private/hosts/predator/networking.nix.example`
- `private/hosts/aurelius/services.nix.example`

Changes:

**predator/services.nix.example**: Add shapes for:
- Attic publisher config (endpoint, cache, token file)
- Attic client substituter (extra-substituters, extra-trusted-public-keys)
- `programs.nh.flake`
- Fish abbrs with Tailscale domain placeholder (from Phase 2)

**predator/networking.nix.example**: Add mDNS resolver shape (systemd service + timer
for resolving a local DNS host). Note that VPN is NM-managed, not wg-quick.

**aurelius/services.nix.example**: Update to show active shape:
- GitHub runner (url, tokenFile, runnerGroup) uncommented
- Grafana/Forgejo domain values (from Phase 2)

Validation:
- `./scripts/check-repo-public-safety.sh` — must PASS
- `./scripts/run-validation-gates.sh structure` — must PASS

Diff expectation:
- three `.example` files change

Commit target:
- `docs(private): sync service and networking examples with live shapes`

### Phase 4: Minor aurelius default.nix.example cleanup (Low)

Targets:
- `private/hosts/aurelius/default.nix.example`

Changes:
- Use `{ config, ... }:` instead of `{ lib, ... }:` to match live
- Remove `users.mutableUsers = lib.mkForce false;` (live doesn't use it)
- Uncomment sudo rules to match live active shape

Validation:
- `./scripts/check-repo-public-safety.sh` — must PASS

Diff expectation:
- one `.example` file changes

Commit target:
- `docs(private): align aurelius default example with live shape`

### Phase 5: Final validation

- `./scripts/check-repo-public-safety.sh` — must PASS
- `./scripts/run-validation-gates.sh structure` — must PASS
- `./scripts/run-validation-gates.sh` — must PASS
- predator eval — must PASS
- aurelius eval — must PASS
- `grep -r "your-tailnet" modules/` — must return nothing
- Runtime: activate wg-br, verify `curl ifconfig.me` returns aurelius IP (not IPv6)

## Risks

1. Removing domain from grafana/forgejo tracked code means aurelius eval requires
   the private override to set it. If private files are missing, Grafana/Forgejo
   still start but with wrong domain — no hard failure.
   Mitigation: example files document the required shape.

2. NM dispatcher script runs for ALL wireguard connections, not just wg-br.
   This is intentional: IPv6 should be disabled for any WireGuard tunnel.

3. Moving `amdev` abbr to private means it won't exist on a fresh install until
   private files are set up. This is acceptable — it's an operator convenience,
   and private files are always needed for a working deploy anyway.

## Definition of Done

- `curl ifconfig.me` returns aurelius IPv4 when wg-br is active (no IPv6 leak)
- `sysctl net.ipv6.conf.all.disable_ipv6` is `1` while VPN is active, `0` when down
- no `your-tailnet` in tracked module files
- all `.example` files reflect live private shapes
- all validation gates pass
- no mkOption, mkMerge, or specialArgs introduced
- no private keys or real deployment facts in tracked files
