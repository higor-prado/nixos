{ inputs, ... }:
{
  flake.modules.nixos.tailscale =
    { pkgs, ... }:
    {
      services.tailscale = {
        enable = true;
        openFirewall = true;
        extraSetFlags = [ "--accept-dns=true" ];
        package =
          inputs.nixpkgs-tailscale-1-96-5.legacyPackages.${pkgs.stdenv.hostPlatform.system}.tailscale;
      };
    };
}
