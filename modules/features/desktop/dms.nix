{ ... }:
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
  flake.modules = {
    nixos.dms =
      { config, ... }:
      let
        host = config.repo.context.host;
        userName = config.repo.context.userName;
        homeDir = config.users.users.${userName}.home;
      in
      {
        home-manager.sharedModules = [ host.inputs.dms.homeModules.dank-material-shell ];

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
