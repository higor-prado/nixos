{ config, inputs, ... }:
let
  userName = config.username;
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
      { config, lib, ... }:
      let
        homeDir = config.users.users.${userName}.home;
      in
      {
        nixpkgs.overlays = [
          # Upstream dsearch currently installs its user unit with executable
          # bits. systemd warns for executable unit files under /etc/systemd/user.
          (_: prev: {
            dsearch = prev.dsearch.overrideAttrs (old: {
              postFixup = (old.postFixup or "") + ''
                if [ -f "$out/lib/systemd/user/dsearch.service" ]; then
                  chmod 0644 "$out/lib/systemd/user/dsearch.service"
                fi
                if [ -f "$out/share/systemd/user/dsearch.service" ]; then
                  chmod 0644 "$out/share/systemd/user/dsearch.service"
                fi
              '';
            });
          })
        ];

        home-manager.sharedModules = [ inputs.dms.homeModules.dank-material-shell ];

        programs.dsearch.enable = true;

        programs.dank-material-shell.greeter = {
          enable = true;
          compositor.name = lib.mkDefault "niri";
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
