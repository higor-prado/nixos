{ ... }:
{
  flake.modules.nixos.github-runner =
    { pkgs, ... }:
    {
      users.groups.github-runner = { };
      users.users.github-runner = {
        isSystemUser = true;
        group = "github-runner";
        home = "/var/lib/github-runner-aurelius";
        createHome = false;
      };

      systemd.tmpfiles.rules = [
        "d /var/lib/github-runner-aurelius 0755 github-runner github-runner -"
        "d /var/lib/github-runner-aurelius/work 0755 github-runner github-runner -"
      ];

      services.github-runners.aurelius = {
        enable = true;
        name = "aurelius";
        replace = true;
        workDir = "/var/lib/github-runner-aurelius/work";
        extraLabels = [
          "aurelius"
          "nixos"
          "aarch64"
        ];
        extraPackages = [ pkgs.docker ];
        user = "github-runner";
        serviceOverrides = {
          SupplementaryGroups = [ "docker" ];
        };
        # url, tokenFile, runnerGroup → private/hosts/aurelius/services.nix
      };
    };
}
