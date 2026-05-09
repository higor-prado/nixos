{ ... }:
{
  flake.modules.nixos.gdm =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      uwsm = lib.getExe config.programs.uwsm.package;
      hyprlandDesktop = "${config.programs.hyprland.package}/share/wayland-sessions/hyprland.desktop";
      hyprlandUwsmSession = pkgs.writeTextFile {
        name = "hyprland-uwsm-session";
        destination = "/share/wayland-sessions/hyprland-uwsm.desktop";
        text = ''
          [Desktop Entry]
          Name=Hyprland (UWSM)
          Comment=Hyprland compositor managed by UWSM
          Exec=${uwsm} start -e -D Hyprland ${hyprlandDesktop}
          TryExec=${uwsm}
          DesktopNames=Hyprland
          Type=Application
        '';
        passthru.providedSessions = [ "hyprland-uwsm" ];
      };
    in
    {
      nixpkgs.overlays = [
        (_final: prev: {
          gnome-shell = prev.gnome-shell.overrideAttrs (oldAttrs: {
            patches = (oldAttrs.patches or [ ]) ++ [
              ../../../config/desktops/gdm/gnome-shell-gdm-login-dialog-largest-monitor.patch
            ];
          });
        })
      ];

      services.displayManager.gdm.enable = true;
      services.displayManager.defaultSession = "hyprland-uwsm";
      # Keep the direct Hyprland session out of GDM so persisted session
      # history cannot bypass UWSM and skip graphical-session.target.
      services.displayManager.sessionPackages = lib.mkForce [ hyprlandUwsmSession ];

      programs.uwsm.enable = true;
    };
}
