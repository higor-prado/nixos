{ den, ... }:
{
  den.aspects.music-client = den.lib.parametric {
    provides.to-users =
      { host, ... }:
      {
        homeManager =
          { config, pkgs, ... }:
          {
            services.mpd = {
              enable = true;
              enableSessionVariables = false;

              musicDirectory = "${config.home.homeDirectory}/Music";
              dataDir = "${config.home.homeDirectory}/.local/state/mpd";
              playlistDirectory = "${config.home.homeDirectory}/.config/mpd/playlists";
              dbFile = "${config.home.homeDirectory}/.local/state/mpd/database";

              network = {
                listenAddress = "/tmp/mpd_socket";
                port = 6600;
              };

              extraConfig = ''
                auto_update             "yes"
                restore_paused          "yes"

                audio_output {
                    type                "pipewire"
                    name                "PipeWire Output"
                }
              '';
            };

            home.packages = with pkgs; [
              ffmpeg
              (python3.withPackages (ps: [ ps.mutagen ]))
              mpd
              host.customPkgs.rmpc
              host.customPkgs.spotatui
            ];

            xdg.configFile."mpd/mpd.conf".source = builtins.path {
              path = ../../../config/apps/mpd/mpd.conf;
              name = "mpd.conf";
            };
            xdg.configFile."rmpc/config.ron".source = builtins.path {
              path = ../../../config/apps/rmpc/config.ron;
              name = "config.ron";
            };
            xdg.configFile."rmpc/themes/cap_mac.ron".source = builtins.path {
              path = ../../../config/apps/rmpc/themes/cap_mac.ron;
              name = "cap_mac.ron";
            };
          };
      };
  };
}
