{ ... }:
{
  flake.modules.nixos.gnome-keyring =
    { lib, pkgs, ... }:
    {
      services.gnome.gnome-keyring.enable = true;
      services.dbus.packages = [
        pkgs.gcr
        pkgs.seahorse
      ];
      programs.ssh.askPassword = lib.mkDefault "${pkgs.seahorse}/libexec/seahorse/ssh-askpass";
    };

  flake.modules.homeManager.gnome-keyring =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.seahorse ];
    };
}
