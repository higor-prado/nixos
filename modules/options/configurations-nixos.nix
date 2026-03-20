{ lib, config, ... }:
let
  nixosConfigurations = lib.flip lib.mapAttrs config.configurations.nixos (
    _: { module }: lib.nixosSystem { modules = [ module ]; }
  );
  checks = lib.mkMerge (
    lib.mapAttrsToList (
      name: nixos: {
        ${nixos.config.nixpkgs.hostPlatform.system} = {
          "configurations:nixos:${name}" = nixos.config.system.build.toplevel;
        };
      }
    ) nixosConfigurations
  );
in
{
  options.configurations.nixos = lib.mkOption {
    type = lib.types.lazyAttrsOf (
      lib.types.submodule {
        options.module = lib.mkOption {
          type = lib.types.deferredModule;
        };
      }
    );
    default = { };
  };

  config.flake = {
    nixosConfigurations = nixosConfigurations;
    checks = checks;
    dendritic = {
      inherit nixosConfigurations checks;
    };
  };
}
