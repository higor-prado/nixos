{ ... }:
{
  flake.modules.homeManager.media-tools =
    { pkgs, ... }:
    {
      home.packages = [
        pkgs.pavucontrol
        pkgs.pamixer
        pkgs.vlc
        pkgs.yt-dlp
        pkgs.stremio-linux-shell
        pkgs.playerctl    # media playback control (waybar mpris + media keys)
      ];
    };
}
