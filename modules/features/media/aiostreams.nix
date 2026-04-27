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
      systemd.tmpfiles.rules = [
        "d ${dataDir} 0755 root root -"
      ];

      virtualisation.oci-containers.containers.aiostreams = {
        image = "ghcr.io/viren070/aiostreams:latest";
        ports = [ "127.0.0.1:${toString port}:3000" ];
        environment = {
          PORT = "3000";
          DATABASE_URI = "sqlite:///data/db.sqlite";
        };
        environmentFiles = [ envFile ];
        volumes = [ "${dataDir}:/app/data" ];
        autoStart = true;
      };

      # Tailscale Serve: expose aiostreams as HTTPS on the machine's tailnet domain.
      # The NixOS tailscale-serve module uses 'set-config' which only manages
      # subdomains (svc:name) that don't resolve in MagicDNS. Path-based serve
      # on the main device domain requires 'tailscale serve' run as root.
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
          # This repo currently tracks a single tailscale serve route owner on
          # cerebelo (aiostreams). Reset keeps the serve config deterministic
          # before we apply the intended route.
          tailscale serve reset
          tailscale serve --bg --yes http://127.0.0.1:${toString port}
        '';
      };
    };
}
