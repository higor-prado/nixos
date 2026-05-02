{ inputs, ... }:
{
  flake.modules.homeManager.llm-agents =
    { pkgs, ... }:
    let
      llmAgentsPkgs = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
    in
    {
      home.packages = [
        llmAgentsPkgs.claude-code
        llmAgentsPkgs.codex
        llmAgentsPkgs.crush
        llmAgentsPkgs.kilocode-cli
        llmAgentsPkgs.opencode
        llmAgentsPkgs.copilot-cli
        llmAgentsPkgs.omp
        llmAgentsPkgs.pi
        llmAgentsPkgs.gemini-cli
      ];

      home.sessionVariables.POWERLINE_NERD_FONTS = "1";
    };
}
