{ ... }:
{
  flake.modules.homeManager.wayland-tools =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        wlr-randr
        waybar
        wl-clipboard
        libnotify
      ];
    };
}
