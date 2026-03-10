{ pkgs, ... }:
{
  languages.javascript = {
    enable = true;
  };

  languages.typescript = {
    enable = true;
  };

  packages = with pkgs; [
    nodejs_22
    nodePackages.typescript
    nodePackages.typescript-language-server  # vtsls alternative
  ];

  enterShell = ''
    echo "📦 JavaScript/TypeScript devenv loaded"
    echo "Node: $(node --version)"
    echo "TypeScript: $(tsc --version)"
    echo ""
    echo "Neovim integration:"
    echo "  - vtsls LSP: Automatically configured for .ts/.tsx"
    echo "  - js-debug: Debugger for .js/.ts"
    echo ""
    echo "Open any .js/.ts/.tsx file in nvim to start coding!"
  '';
}
