{ inputs, ... }:
{
  flake.modules.homeManager.music-client =
    { config, pkgs, ... }:
    let
      customPkgs = import ../../../pkgs { inherit pkgs inputs; };
      spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
    in
    {
      imports = [ inputs.spicetify-nix.homeManagerModules.spicetify ];

      programs.spicetify = {
        enable = true;
        enabledExtensions = with spicePkgs.extensions; [
          adblockify
          hidePodcasts
          shuffle
        ];
        theme = spicePkgs.themes.catppuccin;
        colorScheme = config.catppuccin.flavor;
      };

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
        customPkgs.rmpc
        customPkgs.spotatui
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
}
