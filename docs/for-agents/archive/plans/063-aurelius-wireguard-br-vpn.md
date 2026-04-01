# Aurelius WireGuard BR VPN Plan

## Goal

Make `aurelius` the WireGuard VPN server for `predator`, replacing the current
use of Tailscale exit-node for this traffic pattern.

The target behavior is:
- `aurelius` terminates a WireGuard tunnel
- `predator` connects to `aurelius` as a WireGuard client
- `predator` can route selected or full traffic through `aurelius`
- the setup is reproducible after rebuild/wipe
- the tracked/private split stays aligned with repo patterns

This is **not** “use a third-party WireGuard provider”. This is:
- self-hosted WireGuard on `aurelius`
- client config on `predator`

## Scope

In scope:
- add a narrow WireGuard server owner for `aurelius`
- extend or keep the WireGuard client owner for `predator`
- define the private override shape for server and client facts
- remove `tailscale-exit-node` from the traffic-routing role
- document bootstrap, validation, and rollback
- prove real connectivity and routing behavior

Out of scope:
- replacing Tailscale entirely
- exposing WireGuard publicly beyond what is required for the tunnel
- multi-client WireGuard fleet management
- third-party VPN provider integration

## Why This Plan Exists

The current repo only has a thin WireGuard client base:
- [networking-wireguard-client.nix](/home/higorprado/nixos/modules/features/system/networking-wireguard-client.nix)

And `aurelius` currently models “VPN egress” through:
- [tailscale-exit-node.nix](/home/higorprado/nixos/modules/features/system/tailscale-exit-node.nix)

That is the wrong model for the stated goal.

The desired shape is:
- WireGuard server on `aurelius`
- WireGuard client on `predator`
- Tailscale remains optional for host access/management, not as the VPN tunnel

## Current State

### What exists

- `predator` already composes:
  - `nixos.networking-wireguard-client`
- `aurelius` currently composes:
  - `nixos.tailscale`
  - `nixos.tailscale-exit-node`
- the existing WireGuard client owner only provides:
  - `wireguard-tools`
  - `networking.firewall.checkReversePath = "loose"`

### What does not exist

- no WireGuard server owner
- no tracked/private contract for:
  - server private key
  - client private key
  - peer public keys
  - tunnel addresses
  - endpoint/port
  - routed subnets / full-tunnel policy
- no bootstrap doc for this VPN shape
- no runtime proof for:
  - handshake
  - interface creation
  - routing
  - internet egress through `aurelius`

## Constraints

1. Do not invent broad custom option surfaces just to toggle the feature.
   Importing the feature is the decision.

2. Private deployment facts belong in gitignored private overrides or private
   files, not tracked code.

3. The owner split must remain narrow:
   - server concerns owned by a server owner
   - client base concerns owned by a client owner
   - host compositions only compose

4. Tailscale can remain enabled for management access if useful, but it must no
   longer be the mechanism that provides VPN egress for this use case.

## Desired End State

- `aurelius` has a tracked WireGuard server owner
- `predator` uses tracked WireGuard client base plus private client binding
- `aurelius` no longer relies on `nixos.tailscale-exit-node`
- private files fully describe:
  - server address/port
  - server private key file
  - client tunnel address
  - client private key file
  - peer public keys
  - routing policy (`AllowedIPs`)
- bootstrap docs explain exactly what manual material must exist on each host
- runtime proof exists for:
  - `wg` handshake
  - interface up on both hosts
  - packet forwarding/NAT on `aurelius`
  - client route actually using the tunnel
- no private secrets are tracked

## Proposed Design

### Server owner

Create:
- `modules/features/system/networking-wireguard-server.nix`

Owner responsibilities:
- open the WireGuard UDP port in firewall
- enable forwarding/NAT behavior needed for VPN egress
- own any stable sysctl/routing settings required for the server role
- install WireGuard tooling if needed

Owner non-responsibilities:
- concrete private keys
- concrete peer lists
- concrete tunnel addresses

Those concrete values stay in private overrides using the real NixOS
WireGuard options.

### Client owner

Keep:
- `modules/features/system/networking-wireguard-client.nix`

Likely keep it thin:
- `wireguard-tools`
- reverse path policy if still genuinely required

Do not bloat it with concrete peer/address facts.

### Private override shape

Use direct lower-level NixOS options in gitignored private files.

Expected private bindings:

On `aurelius`:
- server private key file path
- interface address
- listen port
- peer definition for `predator`
- NAT / external interface facts only if they cannot be inferred safely

On `predator`:
- client private key file path
- interface address
- peer definition pointing to `aurelius`
- `AllowedIPs` policy:
  - full tunnel if that is the intended behavior
  - or narrow subnet routing if not

Preferred home:
- `private/hosts/aurelius/networking.nix`
- `private/hosts/predator/networking.nix`

If those files need new examples, add matching `*.example`.

## Main Technical Decisions To Resolve

### 1. Full tunnel or split tunnel

Choose explicitly:
- `AllowedIPs = 0.0.0.0/0` on `predator` if the goal is “route all internet via `aurelius`”
- or narrower subnets if only BR network routes are wanted

This decision affects:
- DNS handling
- NAT behavior on `aurelius`
- rollback expectations
- runtime proof

### 2. Public reachability of `aurelius`

Decide where the WireGuard endpoint lives:
- public IP / domain on `aurelius`
- or some other stable endpoint

This must be documented as part of the private binding.

### 3. NAT and forwarding ownership

Prefer to keep stable NAT/forwarding semantics in the server owner if they are
inherent to “WireGuard server that provides egress”.

Only leave values private if they are truly deployment-specific.

## Phases

### Phase 0: Freeze the Real Requirement

Clarify and record:
- whether the target is full-tunnel or split-tunnel
- which endpoint `predator` should dial
- whether Tailscale remains for management only

Targets:
- this plan

Validation:
- none beyond explicit written decision

### Phase 1: Add Server Owner

Targets:
- `modules/features/system/networking-wireguard-server.nix`
- `modules/hosts/aurelius.nix`

Changes:
- add a narrow server owner
- compose it in `aurelius`
- remove `nixos.tailscale-exit-node` from `aurelius`

Validation:
- `./scripts/run-validation-gates.sh structure`
- `nix eval --raw path:$PWD#nixosConfigurations.aurelius.config.system.build.toplevel.drvPath`

Commit target:
- `feat(networking): add aurelius wireguard server owner`

### Phase 2: Define Private Contracts

Targets:
- `private/hosts/aurelius/networking.nix.example`
- `private/hosts/predator/networking.nix.example`
- matching real private files if directed

Changes:
- document the exact lower-level NixOS options expected on each host
- do not introduce synthetic `custom.*` surfaces

Validation:
- docs/examples align with actual owner shape
- `./scripts/check-docs-drift.sh`
- `./scripts/check-repo-public-safety.sh`

Commit target:
- `docs(networking): document wireguard private bindings`

### Phase 3: Runtime Apply

Targets:
- `aurelius`
- `predator`

Changes:
- apply `aurelius`
- apply `predator`

Validation:
- on `aurelius`:
  - `systemctl status wg-quick-<iface>.service --no-pager -l`
  - `wg show`
  - `ip addr show <iface>`
  - `sysctl net.ipv4.ip_forward`
- on `predator`:
  - `systemctl status wg-quick-<iface>.service --no-pager -l`
  - `wg show`
  - `ip route`

No commit in this phase by itself.

### Phase 4: Prove Real Traffic

Targets:
- runtime only

Proof requirements:
- handshake established between `predator` and `aurelius`
- `predator` can reach `aurelius` over the tunnel address
- if full-tunnel:
  - public egress from `predator` changes to `aurelius`
- if split-tunnel:
  - intended private routes traverse the tunnel

Validation examples:
- `ping`/`curl` over the tunnel address
- `curl ifconfig.me` or equivalent before/after if full-tunnel
- `ip route get <target>`

Commit target:
- none

### Phase 5: Docs and Rollback

Targets:
- `docs/for-humans/workflows/107-aurelius-service-bootstrap.md`
- `docs/for-humans/workflows/106-deploy-aurelius.md`
- progress log for the active aurelius roadmap

Changes:
- add bootstrap instructions for:
  - key file placement
  - server/client apply order
  - verification commands
  - rollback to no-tunnel state
- document whether Tailscale remains for management only

Validation:
- `./scripts/check-docs-drift.sh`

Commit target:
- `docs(networking): add aurelius wireguard vpn bootstrap and rollback`

## Risks

1. Full-tunnel routing can strand remote access if applied carelessly.
   Mitigation:
   - keep Tailscale SSH access intact during migration
   - apply in `test` mode before `switch`

2. NAT/forwarding may work for the tunnel but break unrelated host traffic.
   Mitigation:
   - keep owner narrow
   - verify routes and firewall explicitly after apply

3. DNS behavior can become confusing in full-tunnel mode.
   Mitigation:
   - decide DNS policy explicitly in the private client binding

4. Secret sprawl.
   Mitigation:
   - key files live only in gitignored private paths or host-local secret files
   - never track private keys or pre-shared keys

## Success Criteria

This plan is complete only when all of the following are true:

- `aurelius` runs as a WireGuard server
- `predator` connects as a WireGuard client
- the tunnel is reproducible from tracked code plus gitignored private bindings
- Tailscale exit-node is no longer the mechanism for this VPN path
- the docs explain bootstrap and rollback clearly
- no private key material is tracked
