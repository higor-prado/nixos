{ ... }:
{
  flake.modules.homeManager.wayland-tools =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        wlr-randr
        wl-clipboard
        libnotify
        grim        # Wayland screenshot tool
        slurp       # Wayland region selector
        hyprpicker  # Hyprland color picker
      ];
    };
}
