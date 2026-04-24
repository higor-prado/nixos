{ ... }:
{
  flake.modules.homeManager.rofi = {
    programs.rofi = {
      enable = true;
      terminal = "kitty";
      modes = [
        "drun"
        "run"
        "window"
      ];
      extraConfig = {
        show-icons = true;
        drun-display-format = "{name}";
        display-drun = "";
        display-run = "";
        display-window = "";
      };
    };

    catppuccin.rofi.enable = true;
  };
}
