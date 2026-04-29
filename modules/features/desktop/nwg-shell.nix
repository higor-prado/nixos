{ ... }:
{
  flake.modules.homeManager.nwg-shell =
    { pkgs, ... }:
    {
      # Trial-only NWG shell tools. Keep them manually launched until the user
      # accepts runtime behavior; Waybar/Rofi remain the primary panel/launcher.
      home.packages = [
        pkgs.nwg-dock-hyprland
        pkgs.nwg-panel
        pkgs.nwg-clipman
      ];
    };
}
