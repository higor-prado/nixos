{ ... }:
{
  flake.modules.homeManager.theme-base =
    { pkgs, config, ... }:
    let
      theme = import ./_theme-catalog.nix { inherit pkgs; };
    in
    {
      catppuccin = {
        inherit (theme) flavor accent;
      };
      catppuccin.gtk.icon.enable = false;
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
      catppuccin.foot.enable = true;
      catppuccin.kitty.enable = true;
      catppuccin.chromium.enable = true;
      catppuccin.brave.enable = true;
      catppuccin.firefox.profiles.default = {
        enable = true;
        force = true;
      };
      catppuccin.cava.enable = true;
      catppuccin.waybar.enable = true;
      catppuccin.mako.enable = true;
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
        iconTheme = {
          name = theme.iconTheme.name;
          package = theme.iconTheme.package;
        };
        theme = {
          name = theme.gtkThemeName;
          package = theme.gtkThemePackage;
        };
        font = theme.font // { size = 12; };
      };

      home.pointerCursor = {
        name = theme.cursorTheme.name;
        package = theme.cursorTheme.package;
        size = 24;
        gtk.enable = true;
      };

      home.packages = [
        pkgs.matugen
      ];
    };
}
