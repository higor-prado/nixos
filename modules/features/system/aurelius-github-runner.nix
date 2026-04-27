{ ... }:
{
  # Concrete Aurelius owner: self-hosted GitHub runner service/profile.
  flake.modules.nixos.aurelius-github-runner =
    { pkgs, ... }:
    let
      runnerUser = "github-runner";
      runnerWorkDir = "/var/lib/github-runner-aurelius/work";
    in
    {
      config = {
        users.groups.${runnerUser} = { };
        users.users.${runnerUser} = {
          isSystemUser = true;
          group = runnerUser;
          home = "/var/lib/github-runner-aurelius";
          createHome = false;
        };

        systemd.tmpfiles.rules = [
          "d /var/lib/github-runner-aurelius 0755 ${runnerUser} ${runnerUser} -"
          "d ${runnerWorkDir} 0755 ${runnerUser} ${runnerUser} -"
        ];

        services.github-runners.aurelius = {
          enable = true;
          name = "aurelius";
          replace = true;
          workDir = runnerWorkDir;
          extraLabels = [
            "aurelius"
            "nixos"
            "aarch64"
          ];
          extraPackages = [ pkgs.docker ];
          user = runnerUser;
          serviceOverrides = {
            SupplementaryGroups = [ "docker" ];
          };
        };

        # Concrete GitHub binding stays in the host's private override via
        # services.github-runners.aurelius.url/tokenFile/runnerGroup.
      };
    };
}
