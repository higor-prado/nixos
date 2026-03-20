{ ... }:
{
  flake.modules.homeManager.wayland-tools =
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

  den.aspects.wayland-tools = {
    provides.to-users.homeManager =
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
