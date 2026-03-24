# Aurelius Reproducibility Audit Report

Date: 2026-03-23

Scope:
- Reviewed the current worktree delta.
- Read the required repo docs first.
- Inspected live private files under `private/users/` and `private/hosts/` without copying secrets into this report.
- Compared live private files against tracked `*.example` files.
- Ran the structural/public-safety/eval/build checks listed below.

## Findings

1. High: the repo now documents WireGuard as the canonical `predator` <-> `aurelius` VPN path, but `predator` still has no concrete WireGuard client binding.
   Evidence:
   - `docs/for-humans/workflows/107-aurelius-service-bootstrap.md:199` now says WireGuard is the intended VPN path and `:209` says the client binding belongs in `private/hosts/predator/networking.nix`.
   - `private/hosts/predator/networking.nix:1`-`:59` still contains only the mDNS DNS updater; there is no `networking.wg-quick.interfaces.*`.
   - `private/hosts/predator/networking.nix.example:7`-`:20` shows the expected WireGuard client shape, but the live private file does not implement it.
   Impact:
   - Goal 1 and Goal 3 are not closed for this slice. After a wipe/rebuild, the documented VPN path is not reproducible end-to-end from the current private state on `predator`.

2. High: the mandatory public-safety gate fails in the current tree.
   Evidence:
   - `./scripts/check-repo-public-safety.sh` exited with `FAIL: public safety checks found 3 unallowlisted matches.`
   - The tracked examples contain RFC1918 IPs:
     - `private/hosts/aurelius/networking.nix.example:14`
     - `private/hosts/aurelius/networking.nix.example:20`
     - `private/hosts/predator/networking.nix.example:9`
   Impact:
   - Goal 4 is not met in the repo's own policy sense. Even though these are examples, the publish-safety gate is red, so the tree is not currently public-safe for release.

3. Medium: `predator` persists undeclared WireGuard runtime files under `/etc/wireguard`.
   Evidence:
   - `hardware/predator/persisted-paths.nix:21`-`:22` persists `/etc/wireguard/wg-us.conf` and `/etc/wireguard/wg-br.conf`.
   - A repo-wide search for `wg-us` / `wg-br` in live `.nix` files only finds those persisted paths plus the `aurelius` server binding; there is no corresponding live `predator` ownership for either file.
   Impact:
   - This is a reproducibility risk. Persisting undeclared `/etc/wireguard/*` state allows old tunnel configs to survive wipes/reset cycles and mask the declarative source of truth.

4. Medium: the tracked private-entry examples are stale relative to the live private tree.
   Evidence:
   - `private/hosts/predator/default.nix.example:5`-`:9` imports only `networking.nix`, `services.nix`, and `hardware-local.nix`, while the live file also imports `auth.nix` at `private/hosts/predator/default.nix:3`-`:8`.
   - `private/hosts/aurelius/default.nix.example:7`-`:8` makes `services.nix` optional and does not mention `networking.nix`, while the live file imports both at `private/hosts/aurelius/default.nix:6`-`:9`.
   Impact:
   - Goal 1 is weakened. If someone reconstructs the private layer from the tracked examples after a wipe, they will miss active private wiring that the current systems actually depend on.

## Verified

- Dendritic alignment improved in the desktop/session slice:
  - `modules/desktops/dms-on-niri.nix:1`-`:17` and `modules/desktops/niri-standalone.nix:1`-`:21` now own the greetd session decision directly.
  - `modules/features/desktop/niri.nix:1`-`:32` no longer carries the synthetic `custom.niri.standaloneSession` option.
  - This matches both the repo rules and the reference pattern in `/home/higorprado/git/dendritic/README.md` and `/home/higorprado/git/dendritic/example/modules/desktop.nix`.

- Structural validation passed:
  - `./scripts/run-validation-gates.sh structure`

- Other checks run:
  - `./scripts/check-repo-public-safety.sh` ran and failed as noted above.

- Eval/build checks that passed:
  - `nix eval --raw path:$PWD#nixosConfigurations.aurelius.config.system.build.toplevel.drvPath`
  - `nix eval --raw path:$PWD#nixosConfigurations.predator.config.system.stateVersion` -> `25.11`
  - `nix eval --raw path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.stateVersion` -> `25.11`
  - `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`
  - `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`

## Watchlist

- `flake.lock` was bumped for `dms`, `home-manager`, `llm-agents.nix`, `niri`, `nixpkgs-stable`, `nixpkgs`, and `spotatui`.
- The successful `predator` builds emitted warnings about:
  - deprecated `xorg.libxcb`
  - legacy `gtk.gtk4.theme` default
  - legacy `xdg.userDirs.setSessionVariables` default
- I started a full `aurelius` system build and confirmed that evaluation progressed far enough to materialize `wg-quick-wg-br.service`, but I did not capture a clean final success line before writing this report because the build spent time downloading/building a large closure.
