{ ... }:
{
  flake.modules.homeManager.mime-defaults =
    { ... }:
    let
      # Browsers to remove from web MIME associations
      # (keep only Firefox as the web handler).
      nonFirefoxWebHandlers = [
        "brave-browser.desktop"
        "com.brave.Browser.desktop"
        "chromium-browser.desktop"
        "zen.desktop"
      ];

      # Browsers to remove from image/PDF MIME associations
      # (so dedicated viewers take priority).
      browsersFromMediaHandlers = [
        "brave-browser.desktop"
        "firefox.desktop"
      ];

      imageMimeTypes = [
        "image/jpeg"
        "image/png"
        "image/gif"
        "image/webp"
        "image/avif"
        "image/bmp"
        "image/tiff"
        "image/svg+xml"
      ];

      pdfMimeTypes = [
        "application/pdf"
        "application/x-pdf"
      ];

      webMimeTypes = [
        "text/html"
        "application/xhtml+xml"
        "x-scheme-handler/http"
        "x-scheme-handler/https"
      ];

      mkMimeMap =
        mimeTypes: desktopIds:
        builtins.listToAttrs (
          map (mime: {
            name = mime;
            value = if builtins.isList desktopIds then desktopIds else [ desktopIds ];
          }) mimeTypes
        );
    in
    {
      xdg.mimeApps = {
        defaultApplications =
          (mkMimeMap webMimeTypes "firefox.desktop")
          // (mkMimeMap imageMimeTypes "org.gnome.Loupe.desktop")
          // (mkMimeMap pdfMimeTypes "org.gnome.Papers.desktop")
          // {
            "x-scheme-handler/about" = [ "firefox.desktop" ];
            "x-scheme-handler/unknown" = [ "firefox.desktop" ];
            "application/json" = [ "code.desktop" ];
          };

        associations.added =
          (mkMimeMap webMimeTypes "firefox.desktop")
          // (mkMimeMap imageMimeTypes "org.gnome.Loupe.desktop")
          // (mkMimeMap pdfMimeTypes "org.gnome.Papers.desktop");

        associations.removed =
          (mkMimeMap webMimeTypes nonFirefoxWebHandlers)
          // (mkMimeMap imageMimeTypes browsersFromMediaHandlers)
          // (mkMimeMap pdfMimeTypes browsersFromMediaHandlers);
      };
    };
}
