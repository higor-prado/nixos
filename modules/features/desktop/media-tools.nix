{ ... }:
{
  flake.modules.homeManager.media-tools =
    { pkgs, ... }:
    {
      home.packages = [
        pkgs.pavucontrol
        pkgs.vlc
        pkgs.yt-dlp
      ];
    };
}
