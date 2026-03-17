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
      (den.lib.take.atLeast (
        { host, user }:
        {
          homeManager = {
            home.packages = host.llmAgents.homePackages;
          };
        }
      ))
    ];
  };
}
