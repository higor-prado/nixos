{ ... }:
{
  den.aspects.host-contracts.nixos =
    { lib, ... }:
    {
      options.custom.host.role = lib.mkOption {
        type = lib.types.enum [
          "desktop"
          "server"
        ];
        default = "desktop";
        description = "Host role; set per-host by hardware default.nix as a contract signal read by validation scripts. Must not be used as a conditional in module code.";
      };
    };
}
