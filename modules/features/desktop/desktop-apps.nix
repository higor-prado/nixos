{ inputs, ... }:
{
  flake.modules.homeManager.desktop-apps =
    { pkgs, config, ... }:
    {
      programs.firefox = {
        configPath = "${config.xdg.configHome}/mozilla/firefox";
        enable = true;
        profiles.default = {
          id = 0;
          isDefault = true;
          path = "y4loqr0b.default";
          extensions.force = true;
        };
        policies = {
          DisableTelemetry = true;
        };
      };

      programs.chromium = {
        enable = true;
        commandLineArgs = [
          "--ozone-platform-hint=auto"
          "--ozone-platform=wayland"
          "--enable-features=WaylandWindowDecorations,VaapiVideoDecoder,VaapiVideoEncoder"
        ];
      };
      programs.brave = {
        enable = true;
        commandLineArgs = [
          "--ozone-platform-hint=auto"
          "--ozone-platform=wayland"
          "--enable-features=WaylandWindowDecorations,VaapiVideoDecoder,VaapiVideoEncoder"
        ];
      };

      home.packages = [
        inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
        pkgs.teams-for-linux
        pkgs.meld
        pkgs.obsidian
        pkgs.super-productivity
      ];
    };
}
