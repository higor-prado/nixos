{ lib, config, inputs, ... }:
let
  mkShadowHomeModule =
    hostName: userName:
    let
      user = config.repo.users.${userName};
      privateImport =
        if user.privateModule != null && builtins.pathExists user.privateModule then
          [ user.privateModule ]
        else
          [ ];
    in
    {
      imports = [
        config.flake.modules.homeManager.repo-context
      ] ++ privateImport;

      home = {
        username = user.userName;
        homeDirectory = user.homeDirectory;
        stateVersion = user.homeStateVersion;
      };

      repo.context = {
        inherit hostName userName;
        host = config.repo.hosts.${hostName};
        user = user;
      };
    };

  mkShadowHostModule =
    hostName: host:
    let
      trackedGroups = lib.unique (map (userName: config.repo.users.${userName}.primaryGroup) host.trackedUsers);
      primaryUser =
        if host.trackedUsers == [ ] then null else builtins.elemAt host.trackedUsers 0;
    in
    {
      imports = [
        inputs.home-manager.nixosModules.home-manager
        config.flake.modules.nixos.repo-runtime-contracts
        config.flake.modules.nixos.repo-context
      ] ++ host.hardwareImports;

      config = lib.mkMerge [
        {
          nixpkgs.hostPlatform = host.system;
          networking.hostName = hostName;

          system.stateVersion = "25.11";
          custom = {
            host.role = lib.mkDefault host.role;
            user.name = lib.mkDefault (
              if primaryUser == null then
                "user"
              else
                config.repo.users.${primaryUser}.userName
            );
          };

          environment.systemPackages = host.extraSystemPackages;

          users.groups = lib.genAttrs trackedGroups (_: { });
          users.users = lib.genAttrs host.trackedUsers (
            userName:
            let
              user = config.repo.users.${userName};
            in
            {
              isNormalUser = true;
              home = user.homeDirectory;
              group = user.primaryGroup;
              extraGroups = user.extraGroups;
            }
          );

          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            backupFileExtension = "hm-bak";
            users = lib.genAttrs host.homeManagerUsers (userName: mkShadowHomeModule hostName userName);
          };

          repo.context = {
            inherit hostName;
            host = host;
            userName = primaryUser;
            user =
              if primaryUser == null then
                null
              else
                config.repo.users.${primaryUser};
          };
        }
        (lib.mkIf (host.hardwareImports == [ ]) {
          boot.isContainer = true;
          networking.useHostResolvConf = lib.mkForce false;
          fileSystems."/" = {
            device = "none";
            fsType = "tmpfs";
          };
        })
      ];
    };
in
{
  config.configurations.nixos = lib.mapAttrs (
      hostName: host:
      {
        module = mkShadowHostModule hostName host;
      }
    ) config.repo.hosts;
}
