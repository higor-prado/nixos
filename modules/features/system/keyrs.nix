{ den, ... }:
{
  den.aspects.keyrs = den.lib.parametric {
    includes = [
      ({ user, ... }: {
        nixos.users.users.${user.userName}.extraGroups = [ "uinput" ];
      })
    ];

    nixos =
      { ... }:
      {
        hardware.uinput.enable = true;
        services.keyrs.enable = true;
      };
  };
}
