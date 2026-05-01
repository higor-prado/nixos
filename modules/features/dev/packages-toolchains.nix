{ ... }:
{
  flake.modules.homeManager.packages-toolchains =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        gcc
        nodejs
        bun
        sqlite
        tree-sitter
        binutils
        gnumake
        cmake
        libtool
        uv
      ];

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
}
