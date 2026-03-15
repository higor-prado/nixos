{ den, ... }:
{
  den.aspects.keyrs = den.lib.parametric {
    includes = [
      (
        { host, ... }:
        {
          nixos =
            { ... }:
            {
              imports = [ host.inputs.keyrs.nixosModules.default ];

              hardware.uinput.enable = true;
              services.keyrs.enable = true;
            };
        }
      )
    ];
  };
}
