{ ... }:
{
  den.aspects.editor-vscode = {
    homeManager =
      { pkgs, ... }:
      {
        programs.vscode = {
          enable = true;

          package = pkgs.vscode.override {
            commandLineArgs = [
              "--disable-gpu-compositing"
              "--disable-gpu"
            ];
          };

          profiles.default = {
            enableUpdateCheck = false;
            enableExtensionUpdateCheck = true;

            extensions = with pkgs.vscode-extensions; [
              # Python
              ms-python.python
              ms-python.vscode-pylance
              charliermarsh.ruff

              # Rust
              rust-lang.rust-analyzer

              # Git
              eamodio.gitlens

              # Docker
              ms-azuretools.vscode-docker

              # Nix
              jnoortheen.nix-ide
              bbenoist.nix
            ];

            userSettings = {
              "terminal.integrated.fontFamily" = "'JetBrains Mono Nerd Font Mono'";
              "terminal.integrated.lineHeight" = 1.0;
              "terminal.integrated.fontLigatures.enabled" = true;
              "terminal.integrated.fontWeightBold" = "bold";

              "editor.fontFamily" =
                "'JetBrains Mono Nerd Font Mono', Menlo, Monaco, 'Courier New', monospace, 'JetBrains Mono'";
              "editor.fontSize" = 16;
              "editor.minimap.enabled" = false;
              "diffEditor.ignoreTrimWhitespace" = false;

              "redhat.telemetry.enabled" = false;
              "docker.extension.enableComposeLanguageServer" = false;
              "gitlens.ai.model" = "vscode";
              "claudeCode.preferredLocation" = "panel";
            };
          };
        };
      };
  };
}
