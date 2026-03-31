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

  flake.modules.homeManager.keyboard =
    { ... }:
    {
      # Override dead_acute + c → ç (cedilha).
      # The system uses LANG=en_US.UTF-8 whose Compose table maps
      # dead_acute + c → ć (c with acute). This override fixes it for
      # fcitx5 and any other xkbcommon-based input on Wayland.
      home.file.".XCompose".text = ''
        include "%L"
        <dead_acute> <c> : "ç" ccedilla
        <dead_acute> <C> : "Ç" Ccedilla
      '';
    };
}
