{ ... }:
{
  flake.modules.nixos.nix-settings =
    { config, lib, ... }:
    {
      nix.settings = {
        max-jobs = "auto";
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        auto-optimise-store = true;
        substituters = [ "https://cache.numtide.com" ];
        trusted-public-keys = [
          "cache.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
        ];
        narinfo-cache-negative-ttl = 0;
        trusted-users = lib.mkForce (
          [ "root" ]
          ++ config.repo.context.host.trackedUsers
        );
      };

      programs.nh = {
        enable = true;
        clean.enable = true;
        clean.extraArgs = "--keep-since 4d --keep 3";
      };
    };
}
