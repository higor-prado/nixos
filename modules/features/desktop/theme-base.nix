{ ... }:
{
  flake.modules.homeManager.theme-base =
    { pkgs, config, ... }:
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
    in
    {
      catppuccin = {
        inherit flavor accent;
      };
      catppuccin.gtk.icon.enable = true;
      catppuccin.fzf.enable = true;
      catppuccin.btop.enable = true;
      catppuccin.bottom.enable = true;
      catppuccin.bat.enable = true;
      catppuccin.eza.enable = true;
      catppuccin.lazygit.enable = true;
      catppuccin.yazi.enable = true;
      catppuccin.zellij.enable = true;
      catppuccin.starship.enable = true;
      catppuccin.fish.enable = true;
      catppuccin.alacritty.enable = true;
      catppuccin.foot.enable = true;
      catppuccin.ghostty.enable = true;
      catppuccin.kitty.enable = true;
      catppuccin.wezterm.enable = true;
      catppuccin.chromium.enable = true;
      catppuccin.brave.enable = true;
      catppuccin.vivaldi.enable = true;
      catppuccin.firefox.profiles.default = {
        enable = true;
        force = true;
      };
      catppuccin.floorp.profiles.default = {
        enable = true;
        force = true;
      };
      catppuccin.cava.enable = true;
      catppuccin.tmux = {
        enable = true;
        extraConfig = ''
          set -g @catppuccin_window_status_style "rounded"
        '';
      };
      catppuccin.vscode.profiles.default = {
        enable = true;
        icons.enable = true;
      };

      gtk = {
        enable = true;
        gtk4.enable = true;
        gtk4.theme = config.gtk.theme;
        gtk2.extraConfig = ''
          gtk-im-module="fcitx"
        '';
        gtk3.extraConfig = {
          gtk-im-module = "fcitx";
        };
        gtk4.extraConfig = {
          gtk-im-module = "fcitx";
        };
        theme = {
          name = gtkThemeName;
          package = gtkThemePackage;
        };
        font = {
          name = "Sans";
          size = 12;
        };
      };

      home.pointerCursor = {
        name = "phinger-cursors";
        package = pkgs.phinger-cursors;
        size = 24;
        gtk.enable = true;
      };

      home.packages = [ pkgs.matugen ];
    };
}
