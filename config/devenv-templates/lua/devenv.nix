{ pkgs, ... }:
{
  languages.lua = {
    enable = true;
    package = pkgs.lua5_4;
  };

  packages = with pkgs; [
    lua-language-server
    stylua
    lua5_4
  ];

  enterShell = ''
    echo "🌙 Lua devenv loaded"
    echo "Lua: $(lua -v 2>&1 | head -1)"
    echo ""
    echo "Neovim integration:"
    echo "  - lua-language-server: LSP for .lua files"
    echo "  - stylua: Formatter"
    echo ""
    echo "Open any .lua file in nvim to start coding!"
  '';
}
