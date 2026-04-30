{ ... }:
{
  flake.modules.homeManager.terminals =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      footTheme =
        let
          themeFile = "${config.catppuccin.sources.foot}/catppuccin-${config.catppuccin.foot.flavor}.ini";
        in
        pkgs.runCommandLocal "catppuccin-foot-${config.catppuccin.foot.flavor}.ini" { } ''
          sed 's/^\[colors\]$/[colors-dark]/' ${lib.escapeShellArg themeFile} > "$out"
        '';
    in
    {
      home.sessionVariables.TERMINAL = "kitty";

      programs.foot = {
        enable = true;
        settings = {
          main = {
            font = "JetBrainsMono Nerd Font Mono:size=12";
            term = "xterm-256color";
            include = lib.mkForce "${footTheme}";
            pad = "8x8 center-when-maximized-and-fullscreen";
          };
        };
      };

      programs.kitty = {
        enable = true;
        font = {
          name = "JetBrainsMono Nerd Font Mono";
          size = 12;
        };
        settings = {
          term = "xterm-256color";
          scrollback_lines = 10000;
          enable_audio_bell = false;
          background_opacity = "1.0";
          cursor_blink_interval = 0.5;
          tab_bar_style = "powerline";
          window_padding_width = 8;
        };
      };
    };
}
