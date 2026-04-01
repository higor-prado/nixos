# Aurelius WireGuard BR VPN Progress

## Status

In progress

## Related Plan

- [063-aurelius-wireguard-br-vpn.md](/home/higorprado/nixos/docs/for-agents/plans/063-aurelius-wireguard-br-vpn.md)

## Slice 1

- Added a narrow server owner:
  - [networking-wireguard-server.nix](/home/higorprado/nixos/modules/features/system/networking-wireguard-server.nix)
- Kept the existing client owner:
  - [networking-wireguard-client.nix](/home/higorprado/nixos/modules/features/system/networking-wireguard-client.nix)
- Rewired [aurelius.nix](/home/higorprado/nixos/modules/hosts/aurelius.nix):
  - added `nixos.networking-wireguard-server`
  - removed `nixos.tailscale-exit-node`
- Added tracked private-binding shapes:
  - [networking.nix.example](/home/higorprado/nixos/private/hosts/aurelius/networking.nix.example)
  - [networking.nix.example](/home/higorprado/nixos/private/hosts/predator/networking.nix.example)
- Updated human docs to reflect the new VPN direction:
  - [105-private-overrides.md](/home/higorprado/nixos/docs/for-humans/workflows/105-private-overrides.md)
  - [107-aurelius-service-bootstrap.md](/home/higorprado/nixos/docs/for-humans/workflows/107-aurelius-service-bootstrap.md)

## Current State

- The tracked repo now describes the WireGuard server/client split correctly.
- Tailscale remains available for management, but no longer owns the VPN-egress role in tracked composition.
- The slice is still partial because no concrete private WireGuard binding or runtime proof exists yet.
