# Audit 064 Remediation Progress

## Status

In progress

## Related Plan

- [065-audit-064-remediation.md](/home/higorprado/nixos/docs/for-agents/plans/065-audit-064-remediation.md)

## Baseline

- `./scripts/check-repo-public-safety.sh` — FAIL (3 unallowlisted RFC1918 IPs in .example files)
- `./scripts/run-validation-gates.sh structure` — PASS
- predator eval — PASS
- aurelius eval — PASS

## Slices

### Slice 1: Public-safety allowlist

- added allowlist entries for `private/hosts/aurelius/networking.nix.example`, `private/hosts/predator/networking.nix.example`, and `docs/for-agents/plans/065-audit-064-remediation.md`
- `./scripts/check-repo-public-safety.sh` — PASS

### Slice 2: Declarative WireGuard bindings

- added `networking.wg-quick.interfaces.wg-br` and `networking.wg-quick.interfaces.wg-us` to `private/hosts/predator/networking.nix`
- both tunnels: `autostart = false`, privateKeyFile under `/persist/secrets/wireguard/`
- direct lower-level NixOS options only, no mkOption/mkIf
- predator eval — PASS

### Slice 3: Persisted-paths cleanup

- removed `/etc/wireguard/wg-us.conf` and `/etc/wireguard/wg-br.conf` from files
- added `/persist/secrets/wireguard` to directories
- structure validation — PASS
- predator eval — PASS

### Slice 4: Stale .example files

- `predator/default.nix.example`: added `./auth.nix` import
- `aurelius/default.nix.example`: added concrete imports for `./networking.nix` and `./services.nix`
- `predator/networking.nix.example`: added wg-us shape, noted mutual exclusivity and autostart = false
- `./scripts/check-repo-public-safety.sh` — PASS
- structure validation — PASS

## Final State

- all four audit findings addressed
- all validation gates pass
- both host evals pass
- remaining: runtime migration (Phase 5) — extract keys to `/persist/secrets/wireguard/`, apply config, test tunnels
