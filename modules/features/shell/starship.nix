{ ... }:
{
  den.aspects.starship = {
    provides.to-users.homeManager =
      { ... }:
      {
        programs.starship = {
          enable = true;
          presets = [
            "catppuccin-powerline"
            "nerd-font-symbols"
          ];
          settings = import ./_starship-settings.nix;
        };
      };
  };
}
