{ ... }:
{
  flake.modules.nixos.gaming =
    { pkgs, ... }:
    {
      boot.kernelModules = [ "ntsync" ];

      programs.steam = {
        enable = true;
        protontricks.enable = true;
        package = pkgs.steam.override {
          extraEnv = {
            GTK_IM_MODULE = "fcitx";
            SDL_IM_MODULE = "fcitx";
            XMODIFIERS = "@im=fcitx";
            PROTON_USE_NTSYNC = "1";
            PROTON_ENABLE_NVAPI = "1";
            # NVIDIA NGX — enables Proton's built-in NVIDIA RTX/DLSS updater,
            # so DLSS-FSR and other NGX features stay current in Proton prefixes.
            PROTON_ENABLE_NGX_UPDATER = "1";
          };
        };
        extraPackages = [ pkgs.fcitx5-gtk ];
      };

      programs.gamemode = {
        enable = true;
        settings.general = {
          desiredgov = "performance";
          inhibit_screensaver = 1;
          renice = 10;
          softrealtime = "auto";
        };
      };
    };

  flake.modules.homeManager.gaming =
    { lib, pkgs, ... }:
    let
      theme = import ./_theme-catalog.nix { inherit pkgs; };
      patchSteamTrayIcon = pkgs.writeShellScript "patch-steam-tray-icon" ''
        steam_icon="$HOME/.local/share/Steam/public/steam_tray_mono.png"

        # Steam advertises an app-local IconThemePath and Waybar opens the PNG
        # from ~/.local/share/Steam/public directly, bypassing the GTK theme's
        # symbolic tray aliases. Keep the app-specific remediation with the
        # Steam owner, but source the tint color from the shared theme catalog.
        if [ -f "$steam_icon" ]; then
          tmp=$(mktemp)
          ${pkgs.imagemagick}/bin/magick "$steam_icon" -alpha on -fill '${theme.accentHex}' -colorize 100 "$tmp"
          mv "$tmp" "$steam_icon"
        fi
      '';
    in
    {
      home.packages = [ pkgs.mangohud ];

      home.activation.patchSteamTrayIcon = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        ${patchSteamTrayIcon}
      '';
    };
}
