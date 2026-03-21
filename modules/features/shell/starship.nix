{ ... }:
{
  flake.modules.homeManager.starship =
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
}
