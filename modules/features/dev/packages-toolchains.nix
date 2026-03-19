{ ... }:
{
  den.aspects.packages-toolchains = {
    nixos =
      { lib, pkgs, ... }:
      {
        environment.systemPackages = with pkgs; [
          gcc
          nodejs
          sqlite
          tree-sitter
          binutils
          gnumake
          cmake
          libtool
        ];
      };

    provides.to-users.homeManager =
      { ... }:
      {
        programs.fish.interactiveShellInit = ''
          set --export BUN_INSTALL "$HOME/.bun"
          if test -d "$BUN_INSTALL/bin"
            fish_add_path "$BUN_INSTALL/bin"
          end

          set --export npm_config_prefix "$HOME/.npm-packages"
          if test -d "$HOME/.npm-packages/bin"
            fish_add_path "$HOME/.npm-packages/bin"
          end
        '';
      };
  };
}
