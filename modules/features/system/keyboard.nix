{ ... }:
{
  flake.modules.nixos.keyboard =
    { ... }:
    {
      services.xserver.xkb = {
        layout = "us";
        variant = "alt-intl";
        model = "pc105";
      };

      console.keyMap = "us-acentos";
    };
}
