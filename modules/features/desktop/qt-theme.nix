{ ... }:
{
  flake.modules.homeManager.qt-theme =
    { pkgs, ... }:
    {
      qt = {
        enable = true;
        platformTheme.name = "qtct";
        style.name = "kvantum";
        kvantum.enable = true;
      };

      catppuccin.qt5ct.enable = true;
      catppuccin.kvantum = {
        enable = true;
        apply = true;
      };

      home.packages = with pkgs; [
        libsForQt5.qt5ct
        qt6Packages.qt6ct
        libsForQt5.qtstyleplugin-kvantum
        kdePackages.qtstyleplugin-kvantum
        libsForQt5.qt5.qtwayland
        qt6.qtwayland
      ];
    };
}
