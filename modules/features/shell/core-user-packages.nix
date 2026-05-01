{ ... }:
{
  flake.modules.homeManager.core-user-packages =
    { pkgs, ... }:
    {
      programs.bat.enable = true;
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
        rsync
        restic
        openssh
        fd
        jq
        ripgrep
        sd
        tree
      ];
    };
}
