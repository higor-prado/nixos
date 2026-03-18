# Den schema extension for host context.
# This enables parametric aspects to receive host context via { host, ... } parameters.
# See docs/for-agents/002-den-architecture.md for usage patterns.
{ lib, ... }:
{
  den.schema.host =
    { ... }:
    {
      options = {
        llmAgents = lib.mkOption {
          type = lib.types.submodule {
            options = {
              homePackages = lib.mkOption {
                type = lib.types.listOf lib.types.raw;
                default = [ ];
                description = "Selected LLM agent packages to install at the Home Manager level.";
              };
              systemPackages = lib.mkOption {
                type = lib.types.listOf lib.types.raw;
                default = [ ];
                description = "Selected LLM agent packages to install at the NixOS system level.";
              };
            };
          };
          default = { };
          description = "Semantic host-owned LLM agent package selections.";
        };
        customPkgs = lib.mkOption {
          type = lib.types.raw;
          default = { };
          description = "Custom packages from pkgs/ overlay";
        };
        inputs = lib.mkOption {
          type = lib.types.raw;
          description = "Flake inputs for parametric aspect access";
        };
      };
    };
}
