# Remove Bifrost + apply DNS config to AIOStreams

## Goal

Remove the Bifrost AI gateway from cerebelo and apply the external DNS configuration (Cloudflare `1.1.1.1` + Google `8.8.8.8` fallback) to AIOStreams so its container can resolve external domains.

## Scope

In scope:
- Delete `modules/features/media/bifrost.nix` and `git rm` it
- Remove `nixos.bifrost` from `nixosCoreServices` in `modules/hosts/cerebelo.nix`
- Simplify `tailscale-serve-cerebelo` to only serve aiostreams (single route, no bifrost)
- Add `extraOptions = [ "--dns=1.1.1.1" "--dns=8.8.8.8" ];` to the aiostreams OCI container

Out of scope:
- Any other host or feature module
- The existing aiostreams Tailscale Serve behavior (stays the same)

## Current State

### `modules/features/media/bifrost.nix` (to be deleted)

```nix
{ ... }:
{
  flake.modules.nixos.bifrost =
    { pkgs, ... }:
    let
      dataDir = "/var/lib/bifrost";
      envFile = "/etc/bifrost/bifrost.env";
      port = 8081;
    in
    {
      systemd.tmpfiles.rules = [
        "d ${dataDir} 0750 1000 1000 -"
        "f ${envFile} 0600 root root - -"
      ];
      virtualisation.oci-containers.containers.bifrost = {
        image = "maximhq/bifrost:latest";
        ports = [ "127.0.0.1:${toString port}:8080" ];
        environmentFiles = [ envFile ];
        volumes = [ "${dataDir}:/app/data" ];
        autoStart = true;
        extraOptions = [ "--dns=1.1.1.1" ];
      };
    };
}
```

### `modules/features/media/aiostreams.nix` (current)

```nix
virtualisation.oci-containers.containers.aiostreams = {
  image = "ghcr.io/viren070/aiostreams:latest";
  ports = [ "127.0.0.1:${toString port}:3000" ];
  environment = {
    PORT = "3000";
    DATABASE_URI = "sqlite:///app/data/db.sqlite";
  };
  environmentFiles = [ envFile ];
  volumes = [ "${dataDir}:/app/data" ];
  autoStart = true;
};
```

No `extraOptions` — container inherits host DNS, which may be broken/inaccessible from inside the container namespace.

### `modules/hosts/cerebelo.nix` (current — relevant sections)

```nix
{ inputs, config, ... }:   # top-level (flake-parts module)
  ...
  { pkgs, ... }:            # NixOS module
    nixosCoreServices = [
      ...
      nixos.aiostreams
      nixos.bifrost          # <-- remove
    ];
    ...
    systemd.services.tailscale-serve-cerebelo = {
      ...
      script = ''
        tailscale serve reset
        tailscale serve --bg --yes http://127.0.0.1:3002
        tailscale serve --https=8443 --bg --yes http://127.0.0.1:8081  # <-- remove
      '';
    };
```

## Desired End State

- `modules/features/media/bifrost.nix` — deleted, not tracked
- `modules/features/media/aiostreams.nix` — container has `extraOptions = [ "--dns=1.1.1.1" "--dns=8.8.8.8" ];`
- `modules/hosts/cerebelo.nix` — `nixos.bifrost` removed from `nixosCoreServices`, `tailscale-serve-cerebelo` simplified to only aiostreams route, comment updated
- `{ pkgs, ... }` stays in the NixOS module (still needed for `path = [ pkgs.tailscale ]` in tailscale-serve-cerebelo)

## Phases

### Phase 0: Baseline

Validation:
- `./scripts/run-validation-gates.sh structure`

---

### Phase 1: Remove Bifrost module and host wiring

Targets:
- `modules/features/media/bifrost.nix` — delete file + `git rm`
- `modules/hosts/cerebelo.nix` — remove `nixos.bifrost` from `nixosCoreServices`

Changes:

**`modules/hosts/cerebelo.nix`:**
```diff
       nixosCoreServices = [
         nixos.networking
         nixos.networking-resolved
         nixos.security
         nixos.keyboard
         nixos.maintenance
         nixos.tailscale
         nixos.fish
         nixos.ssh
         nixos.mosh
         nixos.podman
         nixos.aiostreams
-        nixos.bifrost
       ];
```

Validation:
- `nix eval path:$PWD#nixosConfigurations.cerebelo.config.system.build.toplevel.drvPath`

Commit target:
- `refactor(cerebelo): remove bifrost AI gateway`

---

### Phase 2: Simplify tailscale-serve-cerebelo to aiostreams only

Targets:
- `modules/hosts/cerebelo.nix` — remove bifrost route and comment reference

Changes:

```diff
-      # Tailscale Serve: expose cerebelo services as HTTPS on the machine's
-      # tailnet domain. Routes are managed in a single unit so a single `reset`
-      # call keeps the config deterministic — no two feature modules racing.
-      #   aiostreams → :443/
-      #   bifrost    → :8443/
+      # Tailscale Serve: expose aiostreams as HTTPS on the machine's tailnet
+      # domain.
       systemd.services.tailscale-serve-cerebelo = {
         ...
         script = ''
           tailscale serve reset
           tailscale serve --bg --yes http://127.0.0.1:3002
-          tailscale serve --https=8443 --bg --yes http://127.0.0.1:8081
         '';
```

Validation:
- `nix eval path:$PWD#nixosConfigurations.cerebelo.config.system.build.toplevel.drvPath`

Commit target:
- `refactor(cerebelo): simplify tailscale serve to aiostreams only`

---

### Phase 3: Add DNS to aiostreams container

Targets:
- `modules/features/media/aiostreams.nix` — add `extraOptions`

Changes:

```diff
       virtualisation.oci-containers.containers.aiostreams = {
         image = "ghcr.io/viren070/aiostreams:latest";
         ports = [ "127.0.0.1:${toString port}:3000" ];
         environment = {
           PORT = "3000";
           DATABASE_URI = "sqlite:///app/data/db.sqlite";
         };
         environmentFiles = [ envFile ];
         volumes = [ "${dataDir}:/app/data" ];
         autoStart = true;
+        extraOptions = [
+          "--dns=1.1.1.1"
+          "--dns=8.8.8.8"
+        ];
       };
```

`--dns` appears multiple times to set multiple nameservers (podman/docker behavior: each `--dns` adds one entry to `/etc/resolv.conf` inside the container). `1.1.1.1` is Cloudflare (primary), `8.8.8.8` is Google (fallback).

Validation:
- `nix eval path:$PWD#nixosConfigurations.cerebelo.config.system.build.toplevel.drvPath`
- `./scripts/check-extension-contracts.sh`

Commit target:
- `feat(aiostreams): add external DNS to container`

---

### Phase 4: Full validation

- `./scripts/run-validation-gates.sh cerebelo`
- Deploy: `nh os switch path:$HOME/nixos#cerebelo --target-host cerebelo --build-host cerebelo`
- Verify aiostreams container running: `sudo podman ps --filter name=aiostreams`
- Verify DNS inside container: `sudo podman exec aiostreams cat /etc/resolv.conf` shows `1.1.1.1` and `8.8.8.8`
- Verify bifrost is gone: `sudo podman ps --filter name=bifrost` returns empty
- Verify aiostreams accessible: `https://cerebelo.tuna-hexatonic.ts.net/`

## Risks

- None. Removing a feature module + cleaning up host wiring is a straightforward rollback.

## Definition of Done

- [ ] `modules/features/media/bifrost.nix` deleted and `git rm`-ed
- [ ] `modules/hosts/cerebelo.nix` — bifrost removed from nixosCoreServices, tailscale-serve simplified
- [ ] `modules/features/media/aiostreams.nix` — extraOptions with dual DNS added
- [ ] `./scripts/run-validation-gates.sh cerebelo` passes
- [ ] AIOStreams container running with external DNS configured
- [ ] AIOStreams accessible at `https://cerebelo.tuna-hexatonic.ts.net/`
