# Aurelius host composition - server (den-native).
{ den, inputs, config, ... }:
let
  system = "aarch64-linux";
  customPkgs = import ../../pkgs {
    pkgs = inputs.nixpkgs.legacyPackages.${system};
    inherit inputs;
  };
  hostName = "aurelius";
in
{
  repo.hosts.aurelius = {
    inherit system inputs customPkgs;
    role = "server";
    trackedUsers = [ "higorprado" ];
    hardwareImports = [
      inputs.disko.nixosModules.disko
      ../../hardware/aurelius/default.nix
    ];
  };

  configurations.nixos.aurelius.module =
    let
      host = config.repo.hosts.${hostName};
      user = config.repo.users.higorprado;
    in
    {
      imports = [
        inputs.home-manager.nixosModules.home-manager
        config.flake.modules.nixos.repo-runtime-contracts
        config.flake.modules.nixos.repo-context
        config.flake.modules.nixos.higorprado
        config.flake.modules.nixos.nix-settings
        config.flake.modules.nixos.packages-server-tools
        config.flake.modules.nixos.packages-system-tools
        config.flake.modules.nixos.fish
        config.flake.modules.nixos.ssh
      ] ++ host.hardwareImports;

      nixpkgs.hostPlatform = host.system;
      networking.hostName = hostName;
      system.stateVersion = "25.11";

      custom = {
        host.role = host.role;
        user.name = user.userName;
      };

      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        backupFileExtension = "hm-bak";
        users.${user.userName} = {
          imports = [
            config.flake.modules.homeManager.repo-context
            config.flake.modules.homeManager.higorprado
            config.flake.modules.homeManager.core-user-packages
            config.flake.modules.homeManager.fish
            config.flake.modules.homeManager.git-gh
            config.flake.modules.homeManager.ssh
          ];

          repo.context = {
            inherit host;
            inherit hostName;
            inherit user;
            userName = user.userName;
          };
        };
      };

      repo.context = {
        inherit host;
        inherit hostName;
        inherit user;
        userName = user.userName;
      };

      programs.fish.shellAbbrs = {
        naui = "nh os info";
        nausi = "nh os info";
        naust = "nixos-version --json; systemctl --failed --no-pager --legend=0 || true";
        nauc = "nh clean all";
        nauct = "systemctl status nh-clean.timer --no-pager";
      };

      services.openssh.settings.KbdInteractiveAuthentication = false;
    };

  den.hosts.aarch64-linux.aurelius = {
    # Den-level context for parametric aspects
    users.higorprado = { };
    inherit inputs customPkgs;
  };

  den.aspects.aurelius = {
    includes = with den.aspects; [
      server-base
      fish
      ssh
      git-gh
      core-user-packages
      packages-system-tools
      packages-server-tools
    ];

    _.to-users.includes = with den.aspects; [
      fish._.to-users
      ssh._.to-users
      git-gh._.to-users
      core-user-packages._.to-users
    ];

    nixos =
      { ... }:
      {
        config = {
          # Host-specific fish abbreviations (moved from hardware default.nix)
          custom.fish.hostAbbreviationOverrides = {
            naui = "nh os info";
            nausi = "nh os info";
            naust = "nixos-version --json; systemctl --failed --no-pager --legend=0 || true";
            nauc = "nh clean all";
            nauct = "systemctl status nh-clean.timer --no-pager";
          };
        };
        imports = [
          inputs.disko.nixosModules.disko
          ../../hardware/aurelius/default.nix
        ];
      };
  };
}
