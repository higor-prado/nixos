{ ... }:
{
  den.aspects.core-user-packages = {
    homeManager =
      { pkgs, ... }:
      {
        programs.fzf.enable = true;
        programs.btop.enable = true;
        programs.bottom.enable = true;

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
          ripgrep
          fastfetch
          smartmontools
        ];
      };
  };
}
