# zeus host composition - generated skeleton (den-native).
{ den, inputs, ... }:
let
  system = "x86_64-linux";
  customPkgs = import ../../pkgs {
    pkgs = inputs.nixpkgs.legacyPackages.${system};
    inherit inputs;
  };
in
{
  den.hosts.x86_64-linux.zeus = {
    # Canonical tracked user aspect for this personal repo; replace if needed and add
    # classes = [ "homeManager" ] when this host should route HM aspects.
    users.higorprado = { };
    # Example replacement:
    # users.<user-aspect>.classes = [ "homeManager" ];
    inherit inputs customPkgs;
  };

  den.aspects.zeus = {
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
      desktop-dms-on-niri
      niri
      dms
      dms-wallpaper
      desktop-base
      desktop-apps
      desktop-viewers
      wayland-tools
      xwayland
    ];

    nixos = { ... }: {
      config = { };
      imports = [
        ../../hardware/zeus/default.nix
      ];
    };
  };
}
