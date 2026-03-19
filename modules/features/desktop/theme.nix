{ den, ... }:
{
  den.aspects.theme = {
    includes = with den.aspects; [
      theme-base
      theme-zen
    ];

    _.to-users.includes = with den.aspects; [
      theme-base._.to-users
      theme-zen._.to-users
    ];
  };
}
