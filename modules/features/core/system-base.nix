{ den, ... }:
{
  den.aspects.system-base = den.lib.parametric {
    nixos =
      { ... }:
      {
        time.timeZone = "America/Sao_Paulo";

        i18n.defaultLocale = "en_US.UTF-8";
        i18n.supportedLocales = [
          "en_US.UTF-8/UTF-8"
          "pt_BR.UTF-8/UTF-8"
        ];
        i18n.extraLocaleSettings = {
          LC_CTYPE = "pt_BR.UTF-8";
        };

        # NixOS state version
        system.stateVersion = "25.11";
      };
  };
}
