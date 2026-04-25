{ config, ... }:
{
  flake.modules.nixos.nix-settings =
    { lib, ... }:
    {
      nix.settings = {
        max-jobs = "auto";
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        auto-optimise-store = true;
        extra-substituters = [ "https://cache.numtide.com" ];
        extra-trusted-public-keys = [
          "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
        ];
        narinfo-cache-negative-ttl = 1;
        trusted-users = lib.mkForce ([ "root" ] ++ [ config.username ]);
      };

      programs.nh = {
        enable = true;
        clean.enable = true;
        clean.extraArgs = "--keep-since 4d --keep 3";
      };
    };
}
