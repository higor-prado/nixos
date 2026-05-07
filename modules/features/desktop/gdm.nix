{ ... }:
{
  flake.modules.nixos.gdm =
    { ... }:
    {
      services.displayManager.gdm.enable = true;
      services.displayManager.defaultSession = "hyprland-uwsm";
    };
}
