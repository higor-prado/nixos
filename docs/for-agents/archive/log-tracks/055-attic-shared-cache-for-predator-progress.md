# Attic Shared Cache for Predator Progress

## Status

Complete

## Related Plan

- [055-attic-shared-cache-for-predator.md](/home/higorprado/nixos/docs/for-agents/plans/055-attic-shared-cache-for-predator.md)

## Progress

- The Attic runtime was split into narrow owners:
  - [attic-server.nix](/home/higorprado/nixos/modules/features/system/attic-server.nix)
  - [attic-local-publisher.nix](/home/higorprado/nixos/modules/features/system/attic-local-publisher.nix)
  - [attic-publisher.nix](/home/higorprado/nixos/modules/features/system/attic-publisher.nix)
  - [attic-client.nix](/home/higorprado/nixos/modules/features/system/attic-client.nix)
- Host composition stayed clean:
  - [aurelius.nix](/home/higorprado/nixos/modules/hosts/aurelius.nix) composes
    `nixos.attic-server` and `nixos.attic-local-publisher`
  - [predator.nix](/home/higorprado/nixos/modules/hosts/predator.nix) composes
    `nixos.attic-publisher` and `nixos.attic-client`
- Private deployment facts remain private:
  - [services.nix](/home/higorprado/nixos/private/hosts/predator/services.nix)
  - [services.nix.example](/home/higorprado/nixos/private/hosts/predator/services.nix.example)
- A private publisher token file now exists on `predator` under
  `~/.config/attic/`.

## Proofs Completed

- Structure gate passed after the Attic split:
  - `./scripts/run-validation-gates.sh structure`
- Both hosts evaluate cleanly:
  - `nix eval --raw path:$PWD#nixosConfigurations.aurelius.config.system.build.toplevel.drvPath`
  - `nix eval --raw path:$PWD#nixosConfigurations.predator.config.system.build.toplevel.drvPath`
- The new producer path works from `predator`:
  - a real `x86_64-linux` proof derivation was built locally on `predator`
  - a temporary `watch-store` session using the same wiring as the tracked
    producer owner published that path to the Attic server
  - `/tmp/predator-attic-watch.log` contains:
    - `👀 Pushing new store paths to "aurelius" on "remote"`
    - `✅ pn2m99w359w7cf75r6l8dv60xg82mik7-attic-predator-proof-1774147954`
- The shared cache now contains that `predator` output:
  - `nix path-info --store <private-attic-substituter> /nix/store/pn2m99w359w7cf75r6l8dv60xg82mik7-attic-predator-proof-1774147954`
    returned the path successfully
- Consumer proof from `predator` succeeded:
  - the proof path was deleted from the local store
  - `nix-store --realise /nix/store/pn2m99w359w7cf75r6l8dv60xg82mik7-attic-predator-proof-1774147954 -vv`
    fetched it back from the configured private Attic substituter

## Final Proof

- `nh os test path:$PWD` on `predator` activated the tracked
  `attic-watch-store.service`.
- `systemctl status attic-watch-store.service --no-pager -l` confirmed the
  service is active in the real runtime.
- `journalctl -u attic-watch-store.service --since '20 minutes ago' --no-pager`
  showed real publish activity from normal `predator` changes after activation.
- A later real `predator` build produced:
  - `/nix/store/hqyd9pndgg5h7q69sblxxxw0acvlbady-attic-predator-proof-live-1774148431`
- `nix path-info --store <private-attic-substituter> /nix/store/hqyd9pndgg5h7q69sblxxxw0acvlbady-attic-predator-proof-live-1774148431`
  returned that path successfully, proving the active producer service had
  published it to the Attic cache on `aurelius`.
