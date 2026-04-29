{ ... }:
{
  flake.modules.homeManager.vicinae =
    { pkgs, ... }:
    {
      # Trial-only launcher. Keep Rofi as the primary launcher until Vicinae is
      # accepted; no autostart or keybinding is declared here.
      home.packages = [ pkgs.vicinae ];
    };
}
