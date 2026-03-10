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
    dps = "docker ps";
    dpsa = "docker ps -a";
    di = "docker images";
    dex = "docker exec -it";
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
    emacs = "emacsclient -c -a ''";
    e = "emacsclient -c -a ''";
    tf = "switch-terminal foot";
    tg = "switch-terminal ghostty";
    tk = "switch-terminal kitty";
    ta = "switch-terminal alacritty";
    tw = "switch-terminal wezterm";
    claude = "claude";
    cc = "claude";
    opencode = "opencode";
    oc = "opencode";
    crush = "crush";
  };
in
{
  den.aspects.fish = {
    nixos =
      {
        config,
        lib,
        ...
      }:
      {
        options.custom.fish.hostAbbreviationOverrides = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          default = { };
          description = "Host-scoped Fish abbreviations merged into the active Fish surface.";
        };

        config = {
          # System-level abbrs: base + host-specific overrides
          programs.fish.shellAbbrs = baseAbbrs // config.custom.fish.hostAbbreviationOverrides;
        };
      };

    homeManager =
      { ... }:
      {
        catppuccin.fish.enable = true;
        programs.zoxide = {
          enable = true;
          enableFishIntegration = true;
          options = [ "--no-cmd" ];
        };
        programs.fish = {
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

            function switch-terminal
              set terminal $argv[1]
              if test -z "$terminal"
                echo "Usage: switch-terminal <foot|ghostty|kitty|alacritty|wezterm>"
                return 1
              end

              switch $terminal
                case foot ghostty kitty alacritty wezterm
                  set -gx TERMINAL $terminal
                  echo "Default terminal set to: $terminal"
                  echo "Run '$terminal' to launch"
                case '*'
                  echo "Unknown terminal: $terminal"
                  echo "Available: foot, ghostty, kitty, alacritty, wezterm"
                  return 1
              end
            end

            function ai
              set agent $argv[1]
              set dir (pwd)

              if test -z "$agent"
                echo "Available AI agents:"
                echo "  claude, cc  - Claude Code"
                echo "  opencode, oc - OpenCode"
                echo "  crush       - Crush AI"
                return 0
              end

              switch $agent
                case claude cc
                  cd $dir && claude
                case opencode oc
                  cd $dir && opencode
                case crush
                  cd $dir && crush
                case '*'
                  echo "Unknown agent: $agent"
                  ai
              end
            end

            set --export BUN_INSTALL "$HOME/.bun"
            if test -d "$BUN_INSTALL/bin"
              fish_add_path "$BUN_INSTALL/bin"
            end

            set --export npm_config_prefix "$HOME/.npm-packages"
            if test -d "$HOME/.npm-packages/bin"
              fish_add_path "$HOME/.npm-packages/bin"
            end

            if test -d "$HOME/.config/emacs/bin"
              fish_add_path "$HOME/.config/emacs/bin"
            end
          '';
        };
      };
  };
}
