# Aurelius host composition - server (den-native).
{ den, inputs, ... }:
let
  system = "aarch64-linux";
  customPkgs = import ../../pkgs {
    pkgs = inputs.nixpkgs.legacyPackages.${system};
    inherit inputs;
  };
  llmAgentsPkgs = inputs.llm-agents.packages.${system} or { };
  llmAgents = {
    homePackages = [ ];
    systemPackages = with llmAgentsPkgs; [ openclaw ];
  };
in
{
  den.hosts.aarch64-linux.aurelius = {
    # Den-level context for parametric aspects
    users.higorprado = { };
    inherit inputs customPkgs llmAgents;
  };

  den.aspects.aurelius = {
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
      tailscale
      maintenance
      packages-system-tools
      packages-server-tools
      llm-agents
    ];

    nixos =
      { lib, ... }:
      {
        config = {
          # Host-specific fish abbreviations (moved from hardware default.nix)
          custom.fish.hostAbbreviationOverrides = {
            naui = "nh os info";
            nausi = "nh os info";
            naust = "nixos-version --json; systemctl --failed --no-pager --legend=0 || true";
            nauc = "nh clean all";
            nauct = "systemctl status nh-clean.timer --no-pager";
          };
          # Server policy (moved from hardware default.nix)
          custom.ssh.settings = {
            PermitRootLogin = "no";
            PasswordAuthentication = false;
            KbdInteractiveAuthentication = false;
          };
          # Server-specific overrides against desktop-oriented shared defaults.
          users.mutableUsers = true;
          services.getty.autologinUser = null;
          documentation.enable = false;
          services.smartd.enable = lib.mkForce false;
        };
        imports = [
          inputs.disko.nixosModules.disko
          ../../hardware/aurelius/default.nix
        ];
      };
  };
}
