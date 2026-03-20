{ ... }:
{
  flake.modules = {
    nixos.fcitx5 =
      { pkgs, ... }:
      {
        i18n.inputMethod = {
          enable = true;
          type = "fcitx5";
          fcitx5.addons = [ pkgs.fcitx5-gtk ];
        };
      };

    homeManager.fcitx5 =
      { lib, ... }:
      {
        i18n.inputMethod = {
          enable = true;
          type = "fcitx5";
        };
        catppuccin.fcitx5 = lib.mkForce {
          enable = true;
          apply = true;
        };
      };
  };
}
