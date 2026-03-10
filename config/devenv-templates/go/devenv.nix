{ pkgs, ... }:
{
  languages.go = {
    enable = true;
  };

  packages = with pkgs; [
    go
    gopls           # Go LSP server
    gofumpt         # Go formatter (strict gofmt)
    gotools         # Go tools
    golangci-lint   # Go linter (optional, add if needed)
    gore
    gomodifytags
    gotests
    delve
  ];

  enterShell = ''
    echo "🐹 Go devenv loaded"
    echo "Go: $(go version)"
    echo ""
    echo "Neovim integration:"
    echo "  - gopls: LSP for .go files"
    echo "  - gofumpt: Formatter (strict gofmt)"
    echo "  - delve: Debugger (via nvim-dap)"
    echo ""
    echo "Open any .go file in nvim to start coding!"
  '';

}
