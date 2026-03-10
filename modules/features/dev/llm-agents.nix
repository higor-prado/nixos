{ den, ... }:
{
  den.aspects.llm-agents = den.lib.parametric.exactly {
    includes = [
      (
        { host, user, ... }:
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
