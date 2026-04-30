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

    };
}
