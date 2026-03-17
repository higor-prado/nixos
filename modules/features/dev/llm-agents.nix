{ den, ... }:
{
  den.aspects.llm-agents = den.lib.parametric {
    includes = [
      (den.lib.take.atLeast (
        { host, user }:
        {
          nixos = {
            environment.systemPackages = host.llmAgents.systemPackages;
          };

          homeManager = {
            home.packages = host.llmAgents.homePackages;
          };
        }
      ))
    ];
  };
}
