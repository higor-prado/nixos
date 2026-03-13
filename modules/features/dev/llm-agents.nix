{ den, ... }:
{
  den.aspects.llm-agents = den.lib.parametric {
    includes = [
      (
        { host, ... }:
        {
          nixos = {
            environment.systemPackages = host.llmAgents.systemPackages;
          };

          homeManager = {
            home.packages = host.llmAgents.homePackages;
          };
        }
      )
    ];
  };
}
