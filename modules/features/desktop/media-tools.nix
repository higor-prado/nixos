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

  den.aspects.media-tools = {
    provides.to-users.homeManager =
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
