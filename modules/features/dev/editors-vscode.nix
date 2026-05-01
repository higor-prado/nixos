{ ... }:
{
  flake.modules.homeManager.editors-vscode =
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
            "terminal.integrated.fontFamily" = "'JetBrainsMono Nerd Font Mono'";
            "terminal.integrated.lineHeight" = 1.0;
            "terminal.integrated.fontLigatures" = true;
            "terminal.integrated.fontWeightBold" = "bold";

            "editor.fontFamily" = "'JetBrainsMono Nerd Font Mono', Menlo, Monaco, 'Courier New', monospace";
            "editor.fontSize" = 14;
            "editor.fontLigatures" = true;
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
}
