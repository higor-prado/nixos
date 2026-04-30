{ ... }:
{
  flake.modules.homeManager.mako =
    { pkgs, ... }:
    let
      makoWithSystemdActivation = pkgs.mako.overrideAttrs (oldAttrs: {
        postInstall = (oldAttrs.postInstall or "") + ''
          rm -f "$out/share/dbus-1/services/fr.emersion.mako.service"
          install -d "$out/share/dbus-1/services"
          cat > "$out/share/dbus-1/services/org.freedesktop.Notifications.service" <<EOF
[D-BUS Service]
Name=org.freedesktop.Notifications
Exec=$out/bin/mako
SystemdService=mako.service
EOF
        '';
      });
    in
    {
      services.mako = {
        enable = true;
        package = makoWithSystemdActivation;
        settings = {
          font = "JetBrains Mono Nerd Font 12";
          width = 500;
          height = 300;
          margin = 12;
          padding = 15;
          border-size = 2;
          border-radius = 15;
          max-visible = 5;
          default-timeout = 5000;
          icons = true;
          max-icon-size = 64;
          anchor = "top-right";
          layer = "overlay";

          # Keep long-running command completion notifications useful without
          # storing them in history after they expire.
          "app-name=starship summary=\"Command finished\"" = {
            history = false;
            group-by = "app-name,summary,body";
            ignore-timeout = true;
            default-timeout = 5000;
          };

          "urgency=critical" = {
            default-timeout = 0;
          };
          "urgency=low" = {
            default-timeout = 3000;
          };
          "mode=do-not-disturb" = {
            invisible = true;
            default-timeout = 0;
          };
        };
      };
    };
}
