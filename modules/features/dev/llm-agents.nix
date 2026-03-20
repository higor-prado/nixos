{ den, ... }:
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

  den.aspects.llm-agents = den.lib.parametric {
    includes = [
      (den.lib.perHost (
        { host }:
        {
          nixos = {
            environment.systemPackages = host.llmAgents.systemPackages;
          };
        }
      ))
    ];

    provides.to-users =
      { host, ... }:
      {
        homeManager = {
          home.packages = host.llmAgents.homePackages;
        };
      };
  };
}
