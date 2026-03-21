rec {
  # Standard portal exec PATH for systemd user services
  portalExecPath =
    "%h/.nix-profile/bin:"
    + "%h/.local-state/nix/profile/bin:"
    + "/etc/profiles/per-user/%u/bin:"
    + "/nix/profile/bin:"
    + "/nix/var/nix/profiles/default/bin:"
    + "/run/current-system/sw/bin";

  # Ready-to-use xdg.configFile entries for niri desktop compositions
  portalPathOverrides = {
    "systemd/user/xdg-desktop-portal.service.d/override.conf".text = ''
      [Service]
      Environment=PATH=${portalExecPath}
    '';
    "systemd/user/xdg-desktop-portal-gtk.service.d/override.conf".text = ''
      [Service]
      Environment=PATH=${portalExecPath}
    '';
  };
}
