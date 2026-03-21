{ config, inputs, ... }:
let
  topConfig = config;
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
  flake.modules = {
    nixos.dms =
      nixosArgs@{ ... }:
      let
        userName = topConfig.username;
        homeDir = nixosArgs.config.users.users.${userName}.home;
      in
      {
        home-manager.sharedModules = [ inputs.dms.homeModules.dank-material-shell ];

        programs.dsearch.enable = true;

        programs.dank-material-shell.greeter = {
          enable = true;
          compositor.name = "niri";
          configHome = homeDir;
          configFiles = [ "${homeDir}/.config/DankMaterialShell/settings.json" ];
        };
      };

    homeManager.dms =
      { ... }:
      {
        programs.dank-material-shell = {
          enable = true;
        }
        // dmsCommonSettings;
      };
  };
}
