{ ... }:
{
  flake.modules.nixos.aiostreams-tailscale-serve =
    { pkgs, ... }:
    {
      systemd.services.tailscale-serve-aiostreams = {
        description = "Tailscale Serve: AIOStreams HTTPS proxy";
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
          tailscale serve --bg --yes http://127.0.0.1:3002
        '';
      };
    };
}
