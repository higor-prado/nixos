{ ... }:
{
  den.aspects.terminal = {
    homeManager =
      { ... }:
      {
        # Default TERMINAL; override in private.nix via home.sessionVariables.TERMINAL
        home.sessionVariables.TERMINAL = "foot";
      };
  };
}
