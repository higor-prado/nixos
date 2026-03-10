{
  pkgs,
  ...
}:
{
  languages.rust = {
    enable = true;
    components = [
      "rustc"
      "cargo"
      "rust-analyzer"
      "rustfmt"
      "clippy"
    ];
  };

  packages = [
    pkgs.lldb
    pkgs.vscode-extensions.vadimcn.vscode-lldb
  ];

  scripts.codelldb.exec = ''
    exec ${pkgs.vscode-extensions.vadimcn.vscode-lldb}/share/vscode/extensions/vadimcn.vscode-lldb/adapter/codelldb "$@"
  '';

  enterShell = ''
    echo "🦀 Rust devenv loaded"
    echo "Rust: $(rustc --version)"
    echo "Cargo: $(cargo --version)"
    echo ""
    echo "  - rust-analyzer: LSP for .rs files"
    echo "  - rustaceanvim: Auto-attaches debugger"
    echo "  - rustfmt: Formatter"
    echo "  - clippy: Linter"
    echo "  - codelldb: Debugger"
    echo ""
    echo "Open any .rs file in nvim to start coding!"
  '';
}
