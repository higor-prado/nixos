{ pkgs }:

let
  flavor = "mocha";
  accent = "lavender";
  gtkSize = "standard";
  papirusTrayPatched = import ./_papirus-tray-patched.nix {
    inherit pkgs flavor accent;
  };
in
{
  # Raw constants
  inherit flavor accent gtkSize;

  # Derived GTK theme
  gtkThemePackage = pkgs.catppuccin-gtk.override {
    accents = [ accent ];
    variant = flavor;
    size = gtkSize;
  };
  gtkThemeName = "catppuccin-${flavor}-${accent}-${gtkSize}";

  # Shared cursor theme (session + greeter)
  cursorTheme = {
    name = "phinger-cursors";
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
