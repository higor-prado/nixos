{ ... }:
{
  flake.modules.nixos.aiostreams =
    { ... }:
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
          DATABASE_URI = "sqlite:///app/data/db.sqlite";
        };
        environmentFiles = [ envFile ];
        volumes = [ "${dataDir}:/app/data" ];
        autoStart = true;
        extraOptions = [
          "--dns=1.1.1.1"
          "--dns=8.8.8.8"
        ];
      };

    };
}
