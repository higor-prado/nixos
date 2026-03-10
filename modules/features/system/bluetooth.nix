{ den, ... }:
{
  den.aspects.bluetooth = den.lib.parametric {
    includes = [
      ({ user, ... }: {
        nixos.users.users.${user.userName}.extraGroups = [ "rfkill" ];
      })
    ];

    nixos =
      { ... }:
      {
        hardware.bluetooth.enable = true;
        services.blueman.enable = true;
      };
  };
}
