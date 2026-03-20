{ den, ... }:
{
  flake.modules.homeManager.theme-zen =
    { config, lib, pkgs, ... }:
    let
      host = config.repo.context.host;
      flavor = "mocha";
      accent = "lavender";
      capitalize =
        s:
        "${lib.toUpper (builtins.substring 0 1 s)}${
          builtins.substring 1 ((builtins.stringLength s) - 1) s
        }";
      flavorDir = capitalize flavor;
      accentDir = capitalize accent;
      themeDir = "${host.customPkgs.catppuccin-zen-browser}/themes/${flavorDir}/${accentDir}";
      logoFile = "${themeDir}/zen-logo-${flavor}.svg";
      syncZenCatppuccinTheme = pkgs.writeShellScript "sync-zen-catppuccin-theme" ''
        export THEME_DIR=${lib.escapeShellArg themeDir}
        export LOGO_FILE=${lib.escapeShellArg logoFile}
        export GAWK_BIN=${lib.escapeShellArg "${pkgs.gawk}/bin/awk"}
        export GNU_GREP_BIN=${lib.escapeShellArg "${pkgs.gnugrep}/bin/grep"}
        export GNU_SED_BIN=${lib.escapeShellArg "${pkgs.gnused}/bin/sed"}
        export COREUTILS_INSTALL=${lib.escapeShellArg "${pkgs.coreutils}/bin/install"}
        export COREUTILS_PRINTF=${lib.escapeShellArg "${pkgs.coreutils}/bin/printf"}

        ${builtins.readFile ../../../config/apps/zen/sync-catppuccin-theme.sh}
      '';
    in
    {
      home.activation.syncZenCatppuccinTheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        ${syncZenCatppuccinTheme}
      '';
    };

  den.aspects.theme-zen = den.lib.parametric {
    provides.to-users =
      { host, ... }:
      {
        homeManager =
          { lib, pkgs, ... }:
          let
            flavor = "mocha";
            accent = "lavender";
            capitalize =
              s:
              "${lib.toUpper (builtins.substring 0 1 s)}${
                builtins.substring 1 ((builtins.stringLength s) - 1) s
              }";
            flavorDir = capitalize flavor;
            accentDir = capitalize accent;
            themeDir = "${host.customPkgs.catppuccin-zen-browser}/themes/${flavorDir}/${accentDir}";
            logoFile = "${themeDir}/zen-logo-${flavor}.svg";
            syncZenCatppuccinTheme = pkgs.writeShellScript "sync-zen-catppuccin-theme" ''
              export THEME_DIR=${lib.escapeShellArg themeDir}
              export LOGO_FILE=${lib.escapeShellArg logoFile}
              export GAWK_BIN=${lib.escapeShellArg "${pkgs.gawk}/bin/awk"}
              export GNU_GREP_BIN=${lib.escapeShellArg "${pkgs.gnugrep}/bin/grep"}
              export GNU_SED_BIN=${lib.escapeShellArg "${pkgs.gnused}/bin/sed"}
              export COREUTILS_INSTALL=${lib.escapeShellArg "${pkgs.coreutils}/bin/install"}
              export COREUTILS_PRINTF=${lib.escapeShellArg "${pkgs.coreutils}/bin/printf"}

              ${builtins.readFile ../../../config/apps/zen/sync-catppuccin-theme.sh}
            '';
          in
          {
            home.activation.syncZenCatppuccinTheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
              ${syncZenCatppuccinTheme}
            '';
          };
      };
  };
}
