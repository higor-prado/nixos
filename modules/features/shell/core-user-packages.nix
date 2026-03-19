{ ... }:
{
  den.aspects.core-user-packages = {
    provides.to-users.homeManager =
      { pkgs, ... }:
      {
        programs.fzf.enable = true;
        programs.btop = {
          enable = true;
          package = pkgs.btop-cuda;
        };
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
