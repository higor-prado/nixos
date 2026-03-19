{ ... }:
{
  den.aspects.terminals = {
    provides.to-users.homeManager =
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

        programs.ghostty = {
          enable = true;
          settings = {
            "font-family" = "JetBrainsMono Nerd Font Mono";
            "font-size" = 12;
            "font-thicken" = false;
            "window-padding-x" = 6;
            "window-padding-y" = 6;
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

        programs.alacritty = {
          enable = true;
          settings = {
            window = {
              opacity = 1.0;
              dimensions = {
                columns = 80;
                lines = 24;
              };
              padding = {
                x = 4;
                y = 4;
              };
            };
            font = {
              normal = {
                family = "JetBrainsMono Nerd Font Mono";
                style = "Regular";
              };
              size = 12;
            };
          };
        };

        programs.wezterm = {
          enable = true;
          extraConfig = ''
            local wezterm = require 'wezterm'
            local config = {}
            if wezterm.config_builder then
              config = wezterm.config_builder()
            end

            dofile(catppuccin_plugin).apply_to_config(config, catppuccin_config)

            config.font = wezterm.font("JetBrainsMono Nerd Font Mono")
            config.font_size = 12
            config.color_scheme_dirs = { "/usr/share/wezterm/colors" }

            -- Disable audible bell
            config.audible_bell = "Disabled"

            -- Scrollback
            config.scrollback_lines = 10000

            return config
          '';
        };
      };
  };
}
