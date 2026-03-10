{ ... }:
{
  den.aspects.audio.nixos =
    { ... }:
    {
      # PipeWire audio system
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        jack.enable = true;

        # Generic ALSA device reservation (fixes "Device or resource busy" errors)
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

      # RealtimeKit for PipeWire audio
      security.rtkit.enable = true;
    };
}
