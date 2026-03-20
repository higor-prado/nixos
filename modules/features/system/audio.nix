{ ... }:
{
  flake.modules.nixos.audio =
    { ... }:
    {
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        jack.enable = true;

        wireplumber.extraConfig."50-alsa-reservation" = {
          "monitor.alsa.rules" = [
            {
              matches = [ { "device.name" = "~alsa_card.*"; } ];
              actions.update-props = {
                "api.alsa.reserve-device" = true;
              };
            }
          ];
        };
      };

      security.rtkit.enable = true;
    };
}
