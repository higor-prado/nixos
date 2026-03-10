{ ... }:
{
  den.aspects.terminals = {
    homeManager =
      { ... }:
      {
        programs.foot = {
          enable = true;
          settings = {
            main = {
              font = "JetBrains Mono Nerd Font Mono:size=12";
              term = "xterm-256color";
            };
          };
        };

        programs.ghostty = {
          enable = true;
          settings = {
            "font-family" = "JetBrains Mono Nerd Font Mono";
            "font-size" = 12;
            "font-thicken" = false;
          };
        };

        programs.kitty = {
          enable = true;
          font = {
            name = "JetBrains Mono Nerd Font Mono";
            size = 12;
          };
          settings = {
            scrollback_lines = 10000;
            enable_audio_bell = false;
            background_opacity = "1.0";
            cursor_blink_interval = 0;
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
                family = "JetBrains Mono Nerd Font Mono";
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

            config.font = wezterm.font("JetBrains Mono Nerd Font Mono")
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
