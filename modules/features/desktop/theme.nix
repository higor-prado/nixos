{ den, ... }:
{
  den.aspects.theme = {
    includes = with den.aspects; [
      themeBase
      themeZen
    ];
  };
}
