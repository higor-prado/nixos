{ ... }:
{
  flake.modules.homeManager.rofi = {
    programs.rofi = {
      enable = true;
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
  };
}
