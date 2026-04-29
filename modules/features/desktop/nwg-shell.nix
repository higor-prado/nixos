{ ... }:
{
  flake.modules.homeManager.nwg-shell =
    { config, pkgs, ... }:
    let
      dockStyle = "${config.xdg.configHome}/nwg-shell/dock-catppuccin.css";
      nwgDockTrial = pkgs.writeShellApplication {
        name = "nwg-dock-trial";
        runtimeInputs = [
          pkgs.nwg-dock-hyprland
          pkgs.procps
        ];
        text = ''
          if pgrep -x nwg-dock-hyprland >/dev/null; then
            pkill -x nwg-dock-hyprland
            sleep 0.2
          fi

          exec nwg-dock-hyprland -d -nolauncher -i 48 -p bottom -s "${dockStyle}"
        '';
      };
      nwgPanelTrial = pkgs.writeShellApplication {
        name = "nwg-panel-trial";
        runtimeInputs = [ pkgs.nwg-panel ];
        text = ''
          exec nwg-panel "$@"
        '';
      };
      nwgClipmanTrial = pkgs.writeShellApplication {
        name = "nwg-clipman-trial";
        runtimeInputs = [
          pkgs.cliphist
          pkgs.nwg-clipman
          pkgs.wl-clipboard
        ];
        text = ''
          exec nwg-clipman --numbers "$@"
        '';
      };
    in
    {
      # Trial-only NWG shell tools. Keep them manually launched until the user
      # accepts runtime behavior; Waybar/Rofi remain the primary panel/launcher
      # and the existing cliphist service remains the clipboard capture owner.
      home.packages = [
        pkgs.nwg-dock-hyprland
        pkgs.nwg-panel
        pkgs.nwg-clipman
        nwgDockTrial
        nwgPanelTrial
        nwgClipmanTrial
      ];

      xdg.configFile."nwg-shell/dock-catppuccin.css".source = ../../../config/apps/nwg-shell/dock-catppuccin.css;
    };
}
