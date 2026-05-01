{ ... }:
let
  baseAbbrs = {
    l = "eza -alh";
    ll = "eza -l";
    la = "eza -a";
    ls = "eza";
    lt = "eza --tree";
    cat = "bat";
  };

  homeManagerOnlyAbbrs = {
    pym = "python -m";
    gs = "git status";
    gd = "git diff";
    gds = "git diff --staged";
    gp = "git push";
    gl = "git pull";
    lla = "eza -la";
    z = "__zoxide_z";
    zi = "__zoxide_zi";
    venv = "python -m venv .venv && source .venv/bin/activate.fish";
    pipi = "pip install";
    pipp = "pip install --pre";
    ga = "git add";
    gc = "git commit";
    gb = "git branch";
    zed = "uwsm-app zeditor";
  };
in
{
  flake.modules.nixos.fish =
    { ... }:
    {
      config.programs.fish = {
        enable = true;

        shellAbbrs = baseAbbrs;
      };
    };

  flake.modules.homeManager.fish =
    { pkgs, ... }:
    {
      catppuccin.fish.enable = true;
      programs.zoxide = {
        enable = true;
        enableFishIntegration = true;
        options = [ "--no-cmd" ];
      };
      programs.fish = {
        enable = true;
        plugins = [
          {
            name = "fzf.fish";
            src = pkgs.fishPlugins.fzf;
          }
        ];
        shellAbbrs = baseAbbrs // homeManagerOnlyAbbrs;
        interactiveShellInit = ''
          # Suppress default greeting
          function fish_greeting; end

          # Auto-allow direnv in ~/code directory
          function __direnv_auto_allow --on-variable PWD
            if string match -q "$HOME/code/*" $PWD; or string match -q "$HOME/Code/*" $PWD
              and test -f .envrc
              and not direnv status | grep -q "Allowed"
              direnv allow >/dev/null 2>&1
            end
          end

          # Keep Yazi directory-jump convenience from current host.
          function y
            set tmp (mktemp -t "yazi-cwd.XXXXXX")
            command yazi $argv --cwd-file="$tmp"
            if read -z cwd < "$tmp"; and [ "$cwd" != "$PWD" ]; and test -d "$cwd"
              builtin cd -- "$cwd"
            end
            rm -f -- "$tmp"
          end
        '';
      };
    };
}
