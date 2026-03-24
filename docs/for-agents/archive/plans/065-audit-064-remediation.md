# Audit 064 Remediation

## Goal

Close the four findings from the reproducibility audit report
(`docs/for-agents/current/064-aurelius-reproducibility-audit-report.md`) so that the
predator/aurelius WireGuard setup is fully reproducible, the public-safety gate
passes, persisted-paths only reference declaratively owned state, and tracked
`.example` files match their live counterparts.

## Scope

In scope:
- fix the public-safety allowlist for `.example` RFC1918 IPs
- make both WireGuard tunnels (wg-br, wg-us) declarative in predator's private networking
- clean up persisted-paths to match the new declarative ownership
- bring stale `.example` files up to date with their live counterparts

Out of scope:
- changes to the WireGuard server owner on aurelius (already correct)
- changes to the tracked feature modules (`networking-wireguard-server.nix`, `networking-wireguard-client.nix`)
- Tailscale changes
- new custom options or mkIf/mkOption plumbing (dendritic: import is the decision)

## Current State

- `predator` composes `nixos.networking-wireguard-client` (tracked, thin base)
- `aurelius` composes `nixos.networking-wireguard-server` (tracked, narrow infra)
- two imperative WireGuard confs exist at `/etc/wireguard/{wg-br.conf,wg-us.conf}` on predator
- `private/hosts/predator/networking.nix` has only the mDNS DNS updater, no WireGuard binding
- `private/hosts/aurelius/networking.nix` has the full server binding (correct)
- `hardware/predator/persisted-paths.nix` persists both `/etc/wireguard/*.conf` files
- `scripts/public-safety-allowlist.txt` does not include the `.example` files that contain RFC1918 IPs
- `private/hosts/predator/default.nix.example` is missing `./auth.nix` import
- `private/hosts/aurelius/default.nix.example` is missing `./networking.nix` and `./services.nix` imports

## Desired End State

- `./scripts/check-repo-public-safety.sh` passes
- `./scripts/run-validation-gates.sh structure` passes
- both `predator` and `aurelius` eval cleanly
- `private/hosts/predator/networking.nix` declaratively defines both `wg-br` and `wg-us` interfaces via `networking.wg-quick.interfaces.*`
- persisted-paths references only the private key files (not the generated .conf files)
- all tracked `.example` files match the shape of their live counterparts

## Phases

### Phase 0: Baseline

Validation:
- `./scripts/check-repo-public-safety.sh` — FAIL (3 unallowlisted matches) (confirmed)
- `./scripts/run-validation-gates.sh structure` — PASS (confirmed)
- predator eval — PASS (confirmed)
- aurelius eval — PASS (confirmed)

### Phase 1: Fix public-safety allowlist

Targets:
- `scripts/public-safety-allowlist.txt`

Changes:
- add two regex lines to allowlist `.example` files with RFC1918 placeholder IPs

Validation:
- `./scripts/check-repo-public-safety.sh` — must PASS

Diff expectation:
- only `scripts/public-safety-allowlist.txt` changes

Commit target:
- `fix(safety): allowlist RFC1918 placeholders in wireguard example files`

### Phase 2: Declarative WireGuard client bindings on predator

Targets:
- `private/hosts/predator/networking.nix` (private, not tracked)

Changes:
- add `networking.wg-quick.interfaces.wg-br` and `networking.wg-quick.interfaces.wg-us`
- use direct lower-level NixOS options only (no mkOption, mkIf, custom surfaces)
- `autostart = false` on both (mutually exclusive, manual activation)
- privateKeyFile paths under `/persist/secrets/wireguard/`

Validation:
- predator eval — must PASS

Commit target:
- none (private file)

### Phase 3: Clean up persisted-paths

Targets:
- `hardware/predator/persisted-paths.nix`

Changes:
- remove `/etc/wireguard/wg-us.conf` and `/etc/wireguard/wg-br.conf` from `files`
- add `/persist/secrets/wireguard` to `directories`

Validation:
- `./scripts/run-validation-gates.sh structure` — must PASS
- predator eval — must PASS

Diff expectation:
- `hardware/predator/persisted-paths.nix` only

Commit target:
- `fix(predator): replace imperative wireguard confs with declarative key persistence`

### Phase 4: Update stale .example files

Targets:
- `private/hosts/predator/default.nix.example`
- `private/hosts/aurelius/default.nix.example`
- `private/hosts/predator/networking.nix.example`

Changes:
- `predator/default.nix.example`: add `./auth.nix` to imports
- `aurelius/default.nix.example`: add concrete imports for `./networking.nix` and `./services.nix`
- `predator/networking.nix.example`: add `wg-us` example shape, note mutual exclusivity

Validation:
- `./scripts/check-repo-public-safety.sh` — must still PASS
- `./scripts/run-validation-gates.sh structure` — must PASS

Diff expectation:
- three `.example` files change

Commit target:
- `docs(private): sync example files with live private shapes`

### Phase 5: Runtime migration (manual, on predator)

1. Extract private keys to `/persist/secrets/wireguard/{wg-br,wg-us}.key`
2. Apply config via `nh os switch`
3. Test: `sudo wg-quick up wg-br && sudo wg show`

## Risks

1. Both tunnels share `10.66.66.X/24` — cannot run simultaneously.
   Mitigation: `autostart = false` on both.

2. Removing persisted confs before applying could leave a gap.
   Mitigation: apply new config first, then old confs become unused.

## Definition of Done

- `./scripts/check-repo-public-safety.sh` passes
- `./scripts/run-validation-gates.sh structure` passes
- both host evals succeed
- `private/hosts/predator/networking.nix` declares both wg-br and wg-us
- `hardware/predator/persisted-paths.nix` references `/persist/secrets/wireguard`
- all `.example` files match live counterparts
- no mkOption, mkIf, or specialArgs introduced
- no private keys or real IPs in tracked files
