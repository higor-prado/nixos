{ pkgs }:

let
  flavor = "mocha";
  accent = "lavender";
  accentHex = "#b4befe";
  gtkSize = "standard";
  papirusTrayPatched = import ./_papirus-tray-patched.nix {
    inherit pkgs flavor accent accentHex;
  };
in
{
  # Raw constants
  inherit flavor accent accentHex gtkSize;

  # Derived GTK theme
  gtkThemePackage = pkgs.catppuccin-gtk.override {
    accents = [ accent ];
    variant = flavor;
    size = gtkSize;
  };
  gtkThemeName = "catppuccin-${flavor}-${accent}-${gtkSize}";

  # Shared cursor theme (session + greeter)
  cursorTheme = {
    name = "phinger-cursors-dark";
    package = pkgs.phinger-cursors;
  };

  # Icon theme (patched for waybar tray SVG colors)
  iconTheme = {
    name = "Papirus-Dark";
    package = papirusTrayPatched;
  };

  # Font
  font = {
    name = "DejaVu Sans";
    package = pkgs.dejavu_fonts;
  };
}
