{ den, ... }:
{
  den.aspects.theme = {
    includes = with den.aspects; [
      theme-base
      theme-zen
    ];
  };
}
