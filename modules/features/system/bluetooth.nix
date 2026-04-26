{ ... }:
{
  flake.modules.nixos.bluetooth =
    { ... }:
    {
      hardware.bluetooth.enable = true;

      # Keep Blueman system service enabled, but disable NixOS-managed user applet.
      # The blueman package now ships its own user unit with ExecStart; leaving
      # `withApplet = true` here causes duplicate ExecStart entries via drop-ins.
      services.blueman = {
        enable = true;
        withApplet = false;
      };
    };
}
