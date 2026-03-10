{ ... }:
{
  den.aspects.wayland-tools = {
    homeManager =
      { pkgs, ... }:
      {
        home.packages = with pkgs; [
          wlr-randr
          waybar
          swww
          wl-clipboard
          libnotify
        ];
      };
  };
}
