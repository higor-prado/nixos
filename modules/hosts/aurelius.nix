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
    systemPackages = [ ];
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
      server-base
      fish
      ssh
      git-gh
      core-user-packages
      packages-system-tools
      packages-server-tools
      llm-agents
    ];

    nixos =
      { ... }:
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
        };
        imports = [
          inputs.disko.nixosModules.disko
          ../../hardware/aurelius/default.nix
        ];
      };
  };
}
