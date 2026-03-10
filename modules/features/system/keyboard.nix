{ ... }:
{
  den.aspects.keyboard.nixos =
    { ... }:
    {
      # X11 keyboard layout
      services.xserver.xkb = {
        layout = "us";
        variant = "alt-intl";
        model = "pc105";
      };

      # Console keyboard layout
      console.keyMap = "us-acentos";
    };
}
