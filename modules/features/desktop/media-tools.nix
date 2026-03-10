{ ... }:
{
  den.aspects.media-tools = {
    homeManager =
      { pkgs, ... }:
      {
        home.packages = [
          pkgs.pavucontrol
          pkgs.vlc
          pkgs.yt-dlp
        ];
      };
  };
}
