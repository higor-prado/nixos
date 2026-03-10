{ den, ... }:
{
  den.aspects.theme = den.lib.parametric {
    includes = with den.aspects; [
      themeBase
      themeZen
    ];
  };
}
