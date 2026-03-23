{ ... }:
{
  flake.modules.nixos.github-runner =
    { config, lib, pkgs, ... }:
    let
      runnerUser = "github-runner";
      runnerWorkDir = "/var/lib/github-runner-aurelius/work";
      runnerUrl = config.custom.githubRunner.url;
      runnerTokenFile = config.custom.githubRunner.tokenFile;
      runnerGroup = config.custom.githubRunner.runnerGroup;
    in
    {
      options.custom.githubRunner = {
        url = lib.mkOption {
          type = lib.types.nullOr lib.types.singleLineStr;
          default = null;
          description = "Private GitHub repository or organization URL bound to the Aurelius runner.";
        };

        tokenFile = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
          description = "Private token file used to register the Aurelius GitHub runner.";
        };

        runnerGroup = lib.mkOption {
          type = lib.types.nullOr lib.types.singleLineStr;
          default = null;
          description = "Optional private GitHub runner group for the Aurelius runner.";
        };
      };

      config = lib.mkMerge [
        {
          assertions = [
            {
              assertion =
                let
                  allUnset = runnerUrl == null && runnerTokenFile == null && runnerGroup == null;
                  requiredSet = runnerUrl != null && runnerTokenFile != null;
                  optionalGroupOnly = runnerGroup == null || requiredSet;
                in
                allUnset || (requiredSet && optionalGroupOnly);
              message = "custom.githubRunner.url and tokenFile must be set together; runnerGroup is optional but requires both.";
            }
          ];
        }
        (lib.mkIf (runnerUrl != null) {
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
            url = runnerUrl;
            tokenFile = runnerTokenFile;
            runnerGroup = runnerGroup;
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
        })
      ];
    };
}
