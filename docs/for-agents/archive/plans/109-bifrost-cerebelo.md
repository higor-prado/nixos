# Bifrost AI Gateway on Cerebelo

## Goal

Deploy Bifrost AI gateway (`maximhq/bifrost`) as an OCI container on cerebelo and expose it via Tailscale Service (`set-config`), giving it its own TLS subdomain so the Web UI works at `/` without conflicting with aiostreams.

## Scope

In scope:
- Feature module `modules/features/media/bifrost.nix`: OCI container + Tailscale Service via `set-config`
- Tailscale Service config file generated declaratively under `/etc/tailscale-serve/`
- Private env file at `private/hosts/cerebelo/default.nix` (not tracked)
- Host wiring: add `nixos.bifrost` to `nixosCoreServices` in `modules/hosts/cerebelo.nix`

Out of scope:
- Home Manager wiring (Bifrost has no user-facing CLI or config on cerebelo)
- Nix-native build (Go 1.26 not available in nixpkgs; Docker image has `linux/arm64` support)
- Changing aiostreams behavior (existing `tailscale serve` stays untouched)

## Current State

### Reference pattern — `modules/features/media/aiostreams.nix`

```
{ ... }:
{
  flake.modules.nixos.aiostreams =
    { pkgs, ... }:
    let
      dataDir = "/var/lib/aiostreams";
      envFile = "/etc/aiostreams/aiostreams.env";
      port = 3002;
    in
    {
      systemd.tmpfiles.rules = [ "d ${dataDir} 0755 root root -" ];
      virtualisation.oci-containers.containers.aiostreams = {
        image = "ghcr.io/viren070/aiostreams:latest";
        ports = [ "127.0.0.1:${toString port}:3000" ];
        environment = { ... };
        environmentFiles = [ envFile ];
        volumes = [ "${dataDir}:/app/data" ];
        autoStart = true;
      };

      systemd.services.tailscale-serve-aiostreams = {
        description = "Tailscale Serve: aiostreams HTTPS proxy";
        after = [ "tailscaled.service" ];
        wants = [ "tailscaled.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        path = [ pkgs.tailscale ];
        script = ''
          tailscale serve reset
          tailscale serve --bg --yes http://127.0.0.1:${toString port}
        '';
      };
    };
}
```

Key points from this pattern:
- `tailscale serve` on the device domain (`cerebelo.tuna-hexatonic.ts.net`) with path-based routing — aiostreams responds at `/` because it's the only service.
- The comment in the file already documents the alternative: "The NixOS tailscale-serve module uses `set-config` which only manages subdomains (`svc:name`) that don't resolve in MagicDNS."
- Host wiring: `nixos.aiostreams` is in the `nixosCoreServices` list in `modules/hosts/cerebelo.nix`.
- Secrets: `environment.etc."aiostreams/aiostreams.env".text` in `private/hosts/cerebelo/default.nix`.

### Bifrost characteristics (from investigation)

- **Docker image**: `maximhq/bifrost:latest`, supports `linux/arm64` (~59 MB).
- **Internal port**: 8080 (HTTP), serves both API and Web UI.
- **Internal data directory**: `/app/data` (contains `config.json`, SQLite databases, logs).
- **Startup flags**: `-host`, `-port`, `-app-dir`, `-log-level`, `-log-style`. No base-path flag.
- **Web UI**: Built with Vite, base path defaults to `/`. All asset references in `index.html` and generated JS bundles use absolute paths (`/favicon.ico`, `/app/main.tsx`, `/assets/app-hash.js`). Putting it behind a reverse-proxy subpath (e.g., `--set-path=/bifrost`) breaks the UI because the browser resolves assets against `/` instead of `/bifrost/`.
- **API**: Works correctly behind any reverse proxy that strips the prefix. Endpoints like `/v1/chat/completions`, `/v1/models`, `/health` are pure API routes with no path-hardcoded dependencies.

### Tailscale Services vs `tailscale serve`

| Mechanism | Domain | How accessed | Path control |
|---|---|---|---|
| `tailscale serve` | Device domain (`cerebelo.tailnet.ts.net`) | MagicDNS | Path-based routing via `--set-path` |
| `set-config` (Tailscale Service) | Service subdomain (`svc:<name>`) | Virtual IP, service name | Each service owns its own `/` |

Using `set-config` for bifrost means:
- Bifrost gets its own HTTPS domain within the tailnet (via `svc:bifrost`).
- The Web UI works at the root of that domain — no path prefix needed.
- Zero conflict with aiostreams' existing `tailscale serve` on the device domain.
- Declarative: the config is a JSON file, applied once with `tailscale serve set-config`.

## Desired End State

- Bifrost container running on `127.0.0.1:8081` (internal port 8080 mapped to host 8081).
- Persistent data at `/var/lib/bifrost`, mounted as `/app/data` inside the container.
- Secrets in `/etc/bifrost/bifrost.env` (private, not tracked).
- Tailscale Service config JSON at `/etc/tailscale-serve/bifrost-svc.json`, applied via `systemd.services.tailscale-serve-bifrost` (oneshot, `set-config`).
- Bifrost accessible within the tailnet via `svc:bifrost` on HTTPS.
- `aiostreams.nix` unchanged — existing behavior preserved.
- `nixos.bifrost` added to `nixosCoreServices` in `modules/hosts/cerebelo.nix`.

## Phases

### Phase 0: Baseline validation

Ensure the repo is clean before starting.

Validation:
- `./scripts/run-validation-gates.sh structure` must pass.

---

### Phase 1: Create Bifrost feature module

Create `modules/features/media/bifrost.nix`:
- OCI container for `maximhq/bifrost:latest` on port 8081.
- Tailscale Service via `set-config` as a oneshot systemd service — generates the config JSON file declaratively (via `pkgs.writeText` or inline `echo` in `preStart`) and applies it with `tailscale serve set-config`.
- The Tailscale Service JSON exposes the full bifrost HTTP server (API + UI) at `/` under `svc:bifrost`.

**`modules/features/media/bifrost.nix`**

```nix
{ ... }:
{
  flake.modules.nixos.bifrost =
    { pkgs, lib, ... }:
    let
      dataDir = "/var/lib/bifrost";
      envFile = "/etc/bifrost/bifrost.env";
      port = 8081;
      svcName = "svc:bifrost";
      configDir = "/etc/tailscale-serve";
      configFileJson = "${configDir}/bifrost-svc.json";
    in
    {
      systemd.tmpfiles.rules = [
        "d ${dataDir} 0755 root root -"
        "d ${configDir} 0755 root root -"
      ];

      virtualisation.oci-containers.containers.bifrost = {
        image = "maximhq/bifrost:latest";
        ports = [ "127.0.0.1:${toString port}:8080" ];
        environmentFiles = [ envFile ];
        volumes = [ "${dataDir}:/app/data" ];
        autoStart = true;
      };

      # Tailscale Service: expose bifrost as HTTPS on its own service subdomain.
      # set-config manages svc:<name> subdomains that are independent of the
      # device domain, so this doesn't conflict with aiostreams' serve route.
      systemd.services.tailscale-serve-bifrost = {
        description = "Tailscale Serve: bifrost HTTPS proxy (svc:bifrost)";
        after = [ "tailscaled.service" ];
        wants = [ "tailscaled.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        path = [ pkgs.tailscale ];
        script = ''
          install -Dm644 -T <(cat <<'SVCEOF'
          {
            "TCP": {
              "443": {
                "HTTPS": {
                  "${svcName}": {
                    "Handlers": {
                      "/": {
                        "Proxy": "http://127.0.0.1:${toString port}"
                      }
                    }
                  }
                }
              }
            }
          }
          SVCEOF
          ) "${configFileJson}"
          tailscale serve set-config --all "${configFileJson}"
        '';
      };
    };
}
```

Design decisions:
- **Port 8081**: avoids conflict with aiostreams (3002). Chosen over 8080 to keep the default port free.
- **No inlined environment vars**: all secrets live in `/etc/bifrost/bifrost.env` (private).
- **`/app/data` volume**: Docker image stores `config.json`, SQLite databases, and logs here. Persisted on host at `/var/lib/bifrost`.
- **Tailscale Service config file**: written at `/etc/tailscale-serve/bifrost-svc.json` before applying. Keeps the config inspectable and deterministic.
- **`--all` flag**: applies the full service configuration atomically. If more services are added later, we'd extend the same JSON and apply with `--all`.

Validation:
- `./scripts/check-extension-contracts.sh`
- `nix eval path:$PWD#nixosConfigurations.cerebelo.config.system.build.toplevel.drvPath` (after `git add modules/features/media/bifrost.nix`)

Commit target:
- `feat(bifrost): add bifrost AI gateway OCI container and tailscale service`

---

### Phase 2: Update private env file

Append the bifrost env file definition in `private/hosts/cerebelo/default.nix`.

```nix
  # Bifrost — AI gateway for LLM providers.
  environment.etc."bifrost/bifrost.env".text = ''
    # Add provider API keys. Bifrost discovers providers dynamically;
    # setting keys via env enables zero-config startup.
    # OPENAI_API_KEY=sk-...
    # ANTHROPIC_API_KEY=sk-ant-...
  '';
```

This file is gitignored (private/). No secrets in tracked code. Delivered as a local-only change on cerebelo, not committed.

Validation:
- Manual review: verify env file path matches `/etc/bifrost/bifrost.env` referenced in the feature module.

---

### Phase 3: Wire into cerebelo host

Add `nixos.bifrost` to the `nixosCoreServices` list in `modules/hosts/cerebelo.nix`.

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
+        nixos.bifrost
       ];
```

No Home Manager changes needed. No changes to aiostreams. No changes to any other file.

Validation:
- `./scripts/run-validation-gates.sh cerebelo`
- `nix eval path:$PWD#nixosConfigurations.cerebelo.config.system.build.toplevel.drvPath`

Commit target:
- `feat(cerebelo): wire bifrost into cerebelo`

---

### Phase 4: Full validation

- `./scripts/run-validation-gates.sh all`
- Deploy: `nh os switch path:$HOME/nixos`
- Verify container: `sudo podman ps` shows `bifrost`
- Verify local health: `curl http://127.0.0.1:8081/health`
- Verify Tailscale Service was applied: `tailscale serve status` or `tailscale serve get-config --all`
- Verify tailnet access: from another device on the tailnet, `curl https://<svc:bifrost-ip>:443/health` (or however the service is addressed — the exact access pattern depends on the Tailscale Service DNS/virtual-IP implementation)

## Risks

- **Tailscale Service `set-config` JSON format**: the exact format might differ from what's documented above. If the format is wrong, `tailscale serve set-config` will error. Remediation: test the command manually on cerebelo first, then codify the working format.
- **Service accessibility**: `svc:bifrost` may not resolve in MagicDNS (as the aiostreams comment notes). Access may require the service's virtual IP. This is still within the tailnet and secured by Tailscale's access control — it's just a different addressing scheme than a MagicDNS hostname.
- **Port conflict**: if 8081 is in use on cerebelo, the container will fail to bind. Check with `ss -tlnp` before deploying.
- **Container startup time**: first run initializes SQLite and the Web UI. Subsequent restarts are fast.

## Definition of Done

- [ ] `modules/features/media/bifrost.nix` created and `git add`-ed
- [ ] `modules/hosts/cerebelo.nix` updated with `nixos.bifrost` in `nixosCoreServices`
- [ ] `private/hosts/cerebelo/default.nix` has bifrost env file (local-only, not committed)
- [ ] `./scripts/run-validation-gates.sh cerebelo` passes
- [ ] Bifrost container running on cerebelo, reachable at `http://127.0.0.1:8081`
- [ ] Tailscale Service applied and bifrost accessible within the tailnet
}
