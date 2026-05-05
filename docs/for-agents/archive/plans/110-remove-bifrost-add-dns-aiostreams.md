# Remove Bifrost + apply DNS config to AIOStreams

## Goal

Remove the Bifrost AI gateway from cerebelo, keep AIOStreams exposed through
Tailscale Serve, and apply explicit external DNS to the AIOStreams container.

## Scope

In scope:

- `modules/features/media/aiostreams.nix` owns the AIOStreams OCI container.
- `modules/features/media/aiostreams-tailscale-serve.nix` owns the Tailscale
  Serve systemd unit for AIOStreams.
- `modules/hosts/cerebelo.nix` imports both published feature modules explicitly.
- Bifrost remains absent from active modules and host imports.

Out of scope:

- Other hosts.
- Reintroducing a generic service router or feature enable flag.
- Private AIOStreams environment values.

## Desired End State

- `modules/features/media/bifrost.nix` is not tracked.
- `modules/features/media/aiostreams.nix` has AIOStreams container DNS:
  `--dns=1.1.1.1` and `--dns=8.8.8.8`.
- `modules/features/media/aiostreams-tailscale-serve.nix` publishes
  `flake.modules.nixos.aiostreams-tailscale-serve`.
- `modules/hosts/cerebelo.nix` imports `nixos.aiostreams` and
  `nixos.aiostreams-tailscale-serve`; it does not define the Tailscale Serve
  systemd unit inline.

## Repo-pattern constraints

- Feature inclusion is the condition; no `enable` option is needed.
- Service semantics belong in the service owner, not inline in the host file.
- Host composition stays explicit by importing published modules.
- Feature filename matches the published lower-level module name.

## Validation

Static/eval gates:

```bash
./scripts/run-validation-gates.sh structure
nix eval path:$PWD#nixosConfigurations.cerebelo.config.system.build.toplevel.drvPath
```

Runtime gates after deployment:

```bash
nh os switch path:$HOME/nixos#cerebelo --target-host cerebelo --build-host cerebelo
sudo podman ps --filter name=aiostreams
sudo podman exec aiostreams cat /etc/resolv.conf
sudo podman ps --filter name=bifrost
```

Expected runtime results:

- AIOStreams container is running.
- AIOStreams container `/etc/resolv.conf` includes `1.1.1.1` and `8.8.8.8`.
- No Bifrost container is running.
- AIOStreams is reachable at `https://cerebelo.tuna-hexatonic.ts.net/`.

## Definition of Done

- [x] `modules/features/media/bifrost.nix` absent from active tracked files.
- [x] `modules/features/media/aiostreams.nix` owns container DNS.
- [x] `modules/features/media/aiostreams-tailscale-serve.nix` owns Tailscale Serve.
- [x] `modules/hosts/cerebelo.nix` imports both AIOStreams feature modules.
- [x] Static/eval validation passes after the owner split.
- [x] Runtime deployment confirms container DNS and tailnet access.

## Archive rule

Runtime deployment checks passed. This plan is ready to archive under
`docs/for-agents/archive/plans/`.
