{ ... }:
{
  den.aspects.terminal = {
    homeManager =
      { ... }:
      {
        # Default TERMINAL; override in your private user override if needed.
        home.sessionVariables.TERMINAL = "foot";
      };
  };
}
