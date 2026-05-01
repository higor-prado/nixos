{ ... }:
{
  flake.modules.nixos.fonts =
    { pkgs, ... }:
    {
      fonts.packages = with pkgs; [
        noto-fonts
        noto-fonts-color-emoji
        noto-fonts-cjk-sans
        fira-code
        fira-code-symbols
        nerd-fonts.fira-code
        nerd-fonts.jetbrains-mono
        nerd-fonts.meslo-lg
        nerd-fonts.symbols-only
        symbola
        dejavu_fonts
        liberation_ttf
        font-awesome
      ];
    };
}
