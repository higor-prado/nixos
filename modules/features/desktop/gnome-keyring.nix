{ ... }:
{
  flake.modules.nixos.gnome-keyring =
    { pkgs, ... }:
    {
      services.gnome.gnome-keyring.enable = true;
      services.dbus.packages = [ pkgs.gcr ];
      programs.seahorse.enable = true;
    };
}
