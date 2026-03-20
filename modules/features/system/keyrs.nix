{ den, ... }:
{
  flake.modules.nixos.keyrs =
    { ... }:
    {
      hardware.uinput.enable = true;
      services.keyrs.enable = true;
    };

  den.aspects.keyrs = den.lib.parametric {
    includes = [
      (den.lib.take.exactly (
        { host }:
        {
          nixos =
            { ... }:
            {
              imports = [ host.inputs.keyrs.nixosModules.default ];

              hardware.uinput.enable = true;
              services.keyrs.enable = true;
            };
        }
      ))
    ];
  };
}
