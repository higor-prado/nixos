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
        narinfo-cache-negative-ttl = 1;
        trusted-users = lib.mkForce ([ "root" ] ++ [ config.username ]);
      };

      programs.nh = {
        enable = true;
        clean.enable = true;
        clean.extraArgs = "--keep-since 4d --keep 3";
      };

      # ══════════════════════════════════════════════
      # Nix Daemon Scheduling
      # ══════════════════════════════════════════════
      # Run nix-daemon at idle CPU/IO priority so builds never preempt other processes.
      # Strong guarantee that prevents compilation from freezing hosts.
      nix.daemonCPUSchedPolicy = "idle";
      nix.daemonIOSchedClass = "idle";
    };
}
