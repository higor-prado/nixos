{ ... }:
{
  flake.modules = {
    nixos.llm-agents =
      { config, ... }:
      {
        environment.systemPackages = config.repo.context.host.llmAgents.systemPackages;
      };

    homeManager.llm-agents =
      { config, ... }:
      {
        home.packages = config.repo.context.host.llmAgents.homePackages;
      };
  };
}
