{ ... }:
{
  flake.modules.nixos.regreet =
    { pkgs, ... }:
    let
      theme = import ./_theme-catalog.nix { inherit pkgs; };
      wallpaper = pkgs.nixos-artwork.wallpapers.catppuccin-mocha;
    in
    {
      programs.regreet = {
        enable = true;

        theme = {
          name = theme.gtkThemeName;
          package = theme.gtkThemePackage;
        };

        cursorTheme = theme.cursorTheme;

        iconTheme = theme.iconTheme;

        font = theme.font // { size = 14; };

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
