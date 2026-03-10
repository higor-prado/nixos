# __HOST_NAME__ host composition - generated skeleton (den-native).
{ den, inputs, ... }:
let
  system = "x86_64-linux";
  customPkgs = import ../../pkgs {
    pkgs = inputs.nixpkgs.legacyPackages.${system};
    inherit inputs;
  };
in
{
  den.hosts.x86_64-linux.__HOST_NAME__ = {
    users.higorprado = { };
    inherit inputs customPkgs;
  };

  den.aspects.__HOST_NAME__ = {
    includes = with den.aspects; [
      den._.hostname
      user-context
      host-contracts
      system-base
      networking
      security
      keyboard
      nix-settings
      fish
      ssh
      terminal
      git-gh
      core-user-packages
    ];

    nixos = { ... }: {
      config = { };
      imports = [
        ../../hardware/__HOST_NAME__/default.nix
      ];
    };
  };
}
