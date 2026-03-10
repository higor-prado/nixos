# ci-runner host composition - generated skeleton (den-native).
{ den, inputs, ... }:
let
  system = "x86_64-linux";
  customPkgs = import ../../pkgs {
    pkgs = inputs.nixpkgs.legacyPackages.${system};
    inherit inputs;
  };
in
{
  den.hosts.x86_64-linux.ci-runner = {
    users.higorprado = { };
    inherit inputs customPkgs;
  };

  den.aspects.ci-runner = {
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
        ../../hardware/ci-runner/default.nix
      ];
    };
  };
}
