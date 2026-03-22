# Forgejo Predator Access Progress

## Status

Completed

## Related Plan

- [054-forgejo-predator-access-plan.md](/home/higorprado/nixos/docs/for-agents/plans/054-forgejo-predator-access-plan.md)

## Baseline

- The previous Forgejo slice had been removed from active runtime because it
  only proved local host health on `aurelius`.
- The dedicated follow-up now freezes the intended consumer path as:
  - `predator` -> Tailscale -> `http://aurelius.your-tailnet.ts.net:3000/`

## Slices

### Slice 1

- Reintroduced a narrow Forgejo owner:
  - [forgejo.nix](/home/higorprado/nixos/modules/features/system/forgejo.nix)
- Reintroduced Forgejo into the `aurelius` host owner cleanly:
  - [aurelius.nix](/home/higorprado/nixos/modules/hosts/aurelius.nix)
- Kept the host owner limited to composition:
  - no Forgejo URL semantics in the host file
  - no Forgejo firewall rule in the host file
  - no SSH auth tweak in the host file
- Moved service-owned state to the correct owners:
  - [forgejo.nix](/home/higorprado/nixos/modules/features/system/forgejo.nix)
    now owns:
    - `HTTP_ADDR = "0.0.0.0"`
    - `HTTP_PORT = 3000`
    - `DOMAIN = "aurelius.your-tailnet.ts.net"`
    - `ROOT_URL = "http://aurelius.your-tailnet.ts.net:3000/"`
    - `networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 3000 ]`
  - [ssh.nix](/home/higorprado/nixos/modules/features/system/ssh.nix)
    now owns:
    - `services.openssh.settings.KbdInteractiveAuthentication = false`

### Slice 2

- Reapplied the cleaned host owner on the real `aurelius` runtime.
- Verified both sides of the intended consumer path:
  - host-side:
    - `forgejo.service` is `active`
    - Forgejo listens on `*:3000`
    - `curl -I http://127.0.0.1:3000` returns `HTTP/1.1 200 OK`
  - predator-side:
    - `getent ahostsv4 aurelius.your-tailnet.ts.net` resolves to
      `100.98.224.110`
    - `curl -I http://aurelius.your-tailnet.ts.net:3000/` returns
      `HTTP/1.1 200 OK`

## Final State

- The Forgejo slice is now structurally correct and proved from the intended
  Tailscale consumer path.
- The `aurelius` host owner again limits itself to composition.
- The final validation set for this slice passed:
  - `./scripts/run-validation-gates.sh structure`
  - `./scripts/check-docs-drift.sh`
  - `./scripts/run-validation-gates.sh all`
  - `nh os test path:$PWD#aurelius --target-host aurelius --build-host aurelius -e passwordless`
  - `curl -I http://aurelius.your-tailnet.ts.net:3000/` from `predator`
