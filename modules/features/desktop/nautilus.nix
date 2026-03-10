{ ... }:
{
  den.aspects.nautilus = {
    nixos =
      { ... }:
      {
        services.gvfs.enable = true;
        programs.dconf.enable = true;
      };

    homeManager =
      { pkgs, ... }:
      {
        home.packages = with pkgs; [
          nautilus
          tumbler
          ffmpegthumbnailer
          p7zip
          unrar
          file-roller
        ];

        xdg.mimeApps.defaultApplications = {
          "inode/directory" = [ "org.gnome.Nautilus.desktop" ];
          "application/x-gnome-saved-search" = [ "org.gnome.Nautilus.desktop" ];
        };
      };
  };
}
