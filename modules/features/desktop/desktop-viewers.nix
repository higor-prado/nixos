{ ... }:
{
  den.aspects.desktop-viewers = {
    provides.to-users.homeManager =
      { pkgs, ... }:
      let
        loupeDesktop = "org.gnome.Loupe.desktop";
        papersDesktop = "org.gnome.Papers.desktop";
        braveDesktop = "brave-browser.desktop";

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

        mkMimeMap =
          mimeTypes: desktopIds:
          builtins.listToAttrs (
            map (mime: {
              name = mime;
              value = if builtins.isList desktopIds then desktopIds else [ desktopIds ];
            }) mimeTypes
          );

        nonFirefoxWebHandlers = [
          braveDesktop
          "firefox.desktop"
          "google-chrome.desktop"
        ];
      in
      {
        home.packages = with pkgs; [
          loupe
          papers
        ];

        xdg.mimeApps = {
          defaultApplications =
            (mkMimeMap imageMimeTypes loupeDesktop)
            // (mkMimeMap pdfMimeTypes papersDesktop)
            // {
              ".pdf" = [ papersDesktop ];
              ".jpg" = [ loupeDesktop ];
              ".jpeg" = [ loupeDesktop ];
              ".png" = [ loupeDesktop ];
              ".gif" = [ loupeDesktop ];
              ".webp" = [ loupeDesktop ];
              ".svg" = [ loupeDesktop ];
              ".avif" = [ loupeDesktop ];
              ".bmp" = [ loupeDesktop ];
              ".tiff" = [ loupeDesktop ];
            };
          associations.added =
            (mkMimeMap imageMimeTypes loupeDesktop)
            // (mkMimeMap pdfMimeTypes papersDesktop);
          associations.removed =
            (mkMimeMap imageMimeTypes nonFirefoxWebHandlers)
            // (mkMimeMap pdfMimeTypes nonFirefoxWebHandlers);
        };
      };
  };
}
