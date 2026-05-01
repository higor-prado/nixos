# Walker is the Wayland launcher (app runner, calculator, web search).
# Elephant is its clipboard/data backend — it has no purpose without Walker.
# They share this module because Elephant only exists to serve Walker.
{ ... }:
{
  flake.modules.homeManager.walker =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      mutableCopy = import ../../../lib/mutable-copy.nix { inherit lib; };

      # ── Catppuccin theme sync ──────────────────────────────────────
      theme = import ./_theme-catalog.nix { inherit pkgs; };
      walkerThemeName = "catppuccin-${theme.flavor}-${theme.accent}";
      syncWalkerCatppuccinTheme = pkgs.writeShellScript "sync-walker-catppuccin-theme" ''
        export WALKER_THEME_NAME=${lib.escapeShellArg walkerThemeName}
        export WALKER_ACCENT=${lib.escapeShellArg theme.accent}
        export WALKER_CATPPUCCIN_CSS=${lib.escapeShellArg "${config.catppuccin.sources.waybar}/${theme.flavor}.css"}
        export WALKER_STYLE_TEMPLATE=${lib.escapeShellArg "${../../../config/apps/walker/themes/catppuccin/style.css.in}"}
        export COREUTILS_INSTALL=${lib.escapeShellArg "${pkgs.coreutils}/bin/install"}
        export GNU_SED_BIN=${lib.escapeShellArg "${pkgs.gnused}/bin/sed"}

        ${builtins.readFile ../../../config/apps/walker/sync-catppuccin-theme.sh}
      '';

      # ── Elephant package (clipboard/data backend for Walker) ──────
      elephant = pkgs.elephant.override {
        enabledProviders = [
          "bluetooth"
          "bookmarks"
          "calc"
          "clipboard"
          "desktopapplications"
          "files"
          "menus"
          "playerctl"
          "providerlist"
          "runner"
          "snippets"
          "symbols"
          "todo"
          "unicode"
          "websearch"
          "windows"
          "wireplumber"
        ];
      };
    in
    {
      home.packages = [
        elephant
        pkgs.walker
      ];

      # ── Config provisioning (copy-once, mutable at runtime) ───────

      home.activation.provisionWalkerConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] (
        mutableCopy.mkCopyOnce {
          source = ../../../config/apps/walker/config.toml;
          target = "$HOME/.config/walker/config.toml";
        }
      );

      home.activation.syncWalkerCatppuccinTheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        ${syncWalkerCatppuccinTheme}
      '';

      home.activation.provisionElephantConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] (
        mutableCopy.mkCopyOnce {
          source = ../../../config/apps/elephant/elephant.toml;
          target = "$HOME/.config/elephant/elephant.toml";
        }
      );

      home.activation.provisionElephantClipboardConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] (
        mutableCopy.mkCopyOnce {
          source = ../../../config/apps/elephant/clipboard.toml;
          target = "$HOME/.config/elephant/clipboard.toml";
        }
      );

      home.activation.provisionElephantPowerMenu = lib.hm.dag.entryAfter [ "writeBoundary" ] (
        mutableCopy.mkCopyOnce {
          source = ../../../config/apps/elephant/menus/powermenu.toml;
          target = "$HOME/.config/elephant/menus/powermenu.toml";
        }
      );

      home.activation.provisionElephantPowerMenuConfirmLogout =
        lib.hm.dag.entryAfter [ "writeBoundary" ]
          (
            mutableCopy.mkCopyOnce {
              source = ../../../config/apps/elephant/menus/powermenu-confirm-logout.toml;
              target = "$HOME/.config/elephant/menus/powermenu-confirm-logout.toml";
            }
          );

      home.activation.provisionElephantPowerMenuConfirmReboot =
        lib.hm.dag.entryAfter [ "writeBoundary" ]
          (
            mutableCopy.mkCopyOnce {
              source = ../../../config/apps/elephant/menus/powermenu-confirm-reboot.toml;
              target = "$HOME/.config/elephant/menus/powermenu-confirm-reboot.toml";
            }
          );

      home.activation.provisionElephantPowerMenuConfirmShutdown =
        lib.hm.dag.entryAfter [ "writeBoundary" ]
          (
            mutableCopy.mkCopyOnce {
              source = ../../../config/apps/elephant/menus/powermenu-confirm-shutdown.toml;
              target = "$HOME/.config/elephant/menus/powermenu-confirm-shutdown.toml";
            }
          );

      # ── Systemd user services (display-bound) ────────────────────
      systemd.user.services = {
        elephant = {
          Unit = {
            Description = "Elephant data provider service for Walker";
            Documentation = [ "https://github.com/abenz1267/elephant" ];
            ConditionEnvironment = "WAYLAND_DISPLAY";
            PartOf = [ "graphical-session.target" ];
            After = [ "graphical-session.target" ];
          };

          Service = {
            Type = "simple";
            ExecStart = "${elephant}/bin/elephant";
            Restart = "on-failure";
            Environment = "PATH=/run/wrappers/bin:${config.home.profileDirectory}/bin:/run/current-system/sw/bin";
            RestartSec = "2";
          };

          Install.WantedBy = [ "graphical-session.target" ];
        };

        walker = {
          Unit = {
            Description = "Walker launcher service";
            Documentation = [ "https://github.com/abenz1267/walker" ];
            ConditionEnvironment = "WAYLAND_DISPLAY";
            Wants = [ "elephant.service" ];
            After = [
              "graphical-session.target"
              "elephant.service"
            ];
            PartOf = [ "graphical-session.target" ];
          };

          Service = {
            Type = "simple";
            ExecStart = "${pkgs.walker}/bin/walker --gapplication-service";
            Restart = "on-failure";
            RestartSec = "2";
          };

          Install.WantedBy = [ "graphical-session.target" ];
        };
      };
    };
}
