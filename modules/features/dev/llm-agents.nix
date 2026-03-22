{ inputs, ... }:
{
  flake.modules.homeManager.llm-agents =
    { pkgs, ... }:
    {
      home.packages = [
        inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.claude-code
        inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.codex
        inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.crush
        inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.kilocode-cli
        inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.opencode
        inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.copilot-cli
      ];
    };
}
