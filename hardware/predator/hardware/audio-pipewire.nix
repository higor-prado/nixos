{ ... }:
{
  # Fix: HDMI "Device or resource busy" — multi-part mitigation:
  # 51-hdmi-audio: enhanced HDMI audio handling with pause-on-idle
  # 52-reserve-dsp: explicit device reservation for NVIDIA HDMI audio

  services.pipewire.wireplumber.extraConfig."51-hdmi-audio" = {
    "monitor.alsa.rules" = [
      {
        matches = [
          { "device.name" = "~^(hdmi|HDMI).*"; }
          { "node.name" = "~alsa_output.*hdmi.*"; }
        ];
        actions.update-props = {
          "node.pause-on-idle" = true;
          "session.suspend-timeout-seconds" = 5;
          "api.alsa.period-size" = 1024;
          "api.alsa.headroom" = 128;
        };
      }
    ];
  };

  services.pipewire.wireplumber.extraConfig."52-reserve-dsp" = {
    "reserve.device" = [
      {
        matches = [ { "device.name" = "alsa_card.pci-0000_01_00.1"; } ];
        "reserve.device" = "Audio";
        "reserve.priority" = 0;
      }
    ];
  };
}
