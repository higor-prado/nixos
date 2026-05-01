{ ... }:
{
  flake.modules.homeManager.core-user-packages =
    { pkgs, ... }:
    {
      programs.bat.enable = true;
      programs.btop = {
        enable = true;
        package = pkgs.btop-cuda;
      };
      programs.bottom.enable = true;
      programs.eza = {
        enable = true;
        enableFishIntegration = false;
      };
      programs.fzf.enable = true;

      home.packages = with pkgs; [
        vim
        nano
        wget
        curl
        git
        unzip
        file
        htop
        rsync
        restic
        openssh
        fd
        jq
        ripgrep
        sd
        fastfetch
        smartmontools
        tree
      ];
    };
}
