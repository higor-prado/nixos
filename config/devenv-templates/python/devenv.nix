{
  pkgs,
  ...
}:
{
  languages.python = {
    enable = true;
    uv.enable = true;
  };

  packages = [
    pkgs.python3Packages.debugpy
    pkgs.python3Packages.pytest
    pkgs.isort
  ];

  dotenv.enable = true;

  enterShell = ''
    echo "🐍 Python devenv environment loaded"
    echo "Python: $(python --version)"
    echo ""
    echo "Neovim integration:"
    echo "  - pyright LSP: Automatically configured"
    echo "  - ruff: Linting & formatting"
    echo "  - debugpy: Debugger"
    echo ""
    echo "Open any .py file in nvim to start coding!"
  '';
}
