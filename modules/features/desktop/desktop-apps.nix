{ inputs, ... }:
{
  flake.modules.homeManager.desktop-apps =
    { pkgs, config, ... }:
    let
      # Browsers other than Firefox, used to remove them from MIME web handlers
      nonFirefoxWebHandlers = [
        "brave-browser.desktop"
        "com.brave.Browser.desktop"
        "chromium-browser.desktop"
        "zen.desktop"
      ];
    in
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

      xdg.mimeApps = {
        defaultApplications = {
          "text/html" = [ "firefox.desktop" ];
          "application/xhtml+xml" = [ "firefox.desktop" ];
          "x-scheme-handler/http" = [ "firefox.desktop" ];
          "x-scheme-handler/https" = [ "firefox.desktop" ];
          "x-scheme-handler/about" = [ "firefox.desktop" ];
          "x-scheme-handler/unknown" = [ "firefox.desktop" ];
          "application/json" = [ "code.desktop" ];
        };
        associations = {
          added = {
            "text/html" = [ "firefox.desktop" ];
            "application/xhtml+xml" = [ "firefox.desktop" ];
            "x-scheme-handler/http" = [ "firefox.desktop" ];
            "x-scheme-handler/https" = [ "firefox.desktop" ];
          };
          removed = {
            "text/html" = nonFirefoxWebHandlers;
            "application/xhtml+xml" = nonFirefoxWebHandlers;
            "x-scheme-handler/http" = nonFirefoxWebHandlers;
            "x-scheme-handler/https" = nonFirefoxWebHandlers;
          };
        };
      };
    };
}
