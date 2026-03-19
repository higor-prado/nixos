{ den, ... }:
{
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
