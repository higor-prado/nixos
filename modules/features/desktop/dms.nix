{ den, ... }:
let
  dmsCommonSettings = {
    systemd = {
      enable = false;
    };
    enableSystemMonitoring = true;
    enableVPN = true;
    enableDynamicTheming = true;
    enableAudioWavelength = true;
    enableCalendarEvents = true;
    enableClipboardPaste = true;
  };
in
{
  den.aspects.dms = den.lib.parametric {
    provides.to-users.homeManager.programs.dank-material-shell = {
      enable = true;
    }
    // dmsCommonSettings;

    includes = [
      (den.lib.take.exactly (
        { host, ... }:
        {
          nixos =
            { config, lib, ... }:
            let
              trackedUser = import ../../../lib/primary-tracked-user.nix { inherit lib; };
              userName = trackedUser.primaryTrackedUserName host;
              homeDir = config.users.users.${userName}.home;
            in
            {
              imports = [
                host.inputs.dms.nixosModules.dank-material-shell
                host.inputs.dms.nixosModules.greeter
              ];

              home-manager.sharedModules = [ host.inputs.dms.homeModules.dank-material-shell ];

              programs.dsearch.enable = true;

              programs.dank-material-shell.greeter = {
                enable = true;
                compositor.name = "niri";
                configHome = homeDir;
                configFiles = [ "${homeDir}/.config/DankMaterialShell/settings.json" ];
              };
            };
        }
      ))
    ];
  };
}
