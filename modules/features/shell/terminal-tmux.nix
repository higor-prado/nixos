{ ... }:
{
  flake.modules.homeManager.terminal-tmux =
    { pkgs, ... }:
    {
      programs.tmux = {
        enable = true;
        mouse = true;
        terminal = "tmux-256color";
        extraConfig = builtins.readFile ../../../config/tmux/tmux.conf;
      };

      xdg.configFile."tmux/plugins/tmux-plugins".source = pkgs.runCommandLocal "tmux-plugins-dir" { } ''
        mkdir -p "$out"
        ln -s ${pkgs.tmuxPlugins.cpu}/share/tmux-plugins/cpu "$out/tmux-cpu"
      '';
    };

  den.aspects.terminal-tmux = {
    provides.to-users.homeManager =
      { pkgs, ... }:
      {
        programs.tmux = {
          enable = true;
          mouse = true;
          terminal = "tmux-256color";
          extraConfig = builtins.readFile ../../../config/tmux/tmux.conf;
        };

        xdg.configFile."tmux/plugins/tmux-plugins".source = pkgs.runCommandLocal "tmux-plugins-dir" { } ''
          mkdir -p "$out"
          ln -s ${pkgs.tmuxPlugins.cpu}/share/tmux-plugins/cpu "$out/tmux-cpu"
        '';
      };
  };
}
