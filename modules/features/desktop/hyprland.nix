{ inputs, ... }:
{
  flake.modules = {
    nixos.hyprland =
      { pkgs, ... }:
      let
        system = pkgs.stdenv.hostPlatform.system;
      in
      {
        programs.hyprland = {
          enable = true;
          package = inputs.hyprland.packages.${system}.hyprland;
          xwayland.enable = true;
          withUWSM = true;
        };

        programs.hyprlock.enable = true;
        services.hypridle.enable = true;

      };

    homeManager.hyprland =
      { lib, ... }:
      let
        helpers = import ../../../lib/_helpers.nix;
        portalExecPath = helpers.portalExecPath;
      in
      {
        wayland.windowManager.hyprland = {
          enable = true;
          extraConfig = "source = ~/.config/hypr/user.conf";
        };
        xdg.configFile."systemd/user/xdg-desktop-portal-gnome.service.d/override.conf".text = ''
          [Service]
          Environment=PATH=${portalExecPath}
        '';
      };
  };
}
