{ ... }:
{
  flake.modules.nixos.regreet =
    { pkgs, ... }:
    let
      flavor = "mocha";
      accent = "lavender";
      gtkSize = "standard";
      gtkThemePackage = pkgs.catppuccin-gtk.override {
        accents = [ accent ];
        variant = flavor;
        size = gtkSize;
      };
      gtkThemeName = "catppuccin-${flavor}-${accent}-${gtkSize}";
      wallpaper = pkgs.nixos-artwork.wallpapers.catppuccin-mocha;
    in
    {
      programs.regreet = {
        enable = true;

        theme = {
          name = gtkThemeName;
          package = gtkThemePackage;
        };

        cursorTheme = {
          name = "catppuccin-mocha-lavender-cursors";
          package = pkgs.catppuccin-cursors.mochaLavender;
        };

        iconTheme = {
          name = "Papirus-Dark";
          package = pkgs.papirus-icon-theme;
        };

        font = {
          name = "JetBrains Mono Nerd Font";
          package = pkgs.nerd-fonts.jetbrains-mono;
          size = 14;
        };

        extraCss = ''
          /* Catppuccin Mocha fine-tuning for ReGreet */
          window {
            background-color: @base;
          }
        '';

        settings = {
          background = {
            path = "${wallpaper.src}";
            fit = "Cover";
          };
          GTK = {
            application_prefer_dark_theme = true;
          };
        };
      };
    };
}
