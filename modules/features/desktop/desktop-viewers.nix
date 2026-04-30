{ ... }:
{
  flake.modules.homeManager.desktop-viewers =
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
          // (mkMimeMap pdfMimeTypes papersDesktop);
        associations.added =
          (mkMimeMap imageMimeTypes loupeDesktop)
          // (mkMimeMap pdfMimeTypes papersDesktop);
        associations.removed =
          (mkMimeMap imageMimeTypes nonFirefoxWebHandlers)
          // (mkMimeMap pdfMimeTypes nonFirefoxWebHandlers);
      };
    };
}
