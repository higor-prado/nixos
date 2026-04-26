{ pkgs }:

let
  flavor = "mocha";
  accent = "lavender";
  gtkSize = "standard";
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

  # Catppuccin cursor theme (for display managers and similar contexts)
  cursorTheme = {
    name = "catppuccin-mocha-lavender-cursors";
    package = pkgs.catppuccin-cursors.mochaLavender;
  };

  # Icon theme
  iconTheme = {
    name = "Papirus-Dark";
    package = pkgs.papirus-icon-theme;
  };

  # Font
  font = {
    name = "JetBrains Mono Nerd Font";
    package = pkgs.nerd-fonts.jetbrains-mono;
  };
}
