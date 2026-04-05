{ inputs, ... }:
{
  flake.modules.homeManager.desktop-apps =
    { pkgs, ... }:
    let
      nonFirefoxWebHandlers = [
        "brave-browser.desktop"
        "com.brave.Browser.desktop"
        "chromium-browser.desktop"
        "com.google.Chrome.desktop"
        "google-chrome.desktop"
        "zen.desktop"
        "dms-open.desktop"
      ];
    in
    {
      programs.firefox = {
        enable = true;
        profiles.default = {
          id = 0;
          isDefault = true;
          path = "y4loqr0b.default";
          extensions.force = true;
        };
      };

      programs.chromium = {
        enable = true;
        commandLineArgs = [
          "--ozone-platform-hint=auto"
          "--ozone-platform=wayland"
          "--enable-features=WaylandWindowDecorations"
          "--disable-gpu-compositing"
        ];
      };
      programs.brave.enable = true;

      home.packages = [
        inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
        (pkgs.google-chrome.override {
          commandLineArgs = [
            "--ozone-platform-hint=auto"
            "--ozone-platform=wayland"
            "--enable-features=WaylandWindowDecorations"
            "--disable-gpu-compositing"
          ];
        })
        pkgs.teams-for-linux
        pkgs.meld
        pkgs.obsidian
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
