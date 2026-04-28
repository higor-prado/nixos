{ ... }:
let
  gitIgnoreSource = ../../../config/apps/git/ignore;
in
{
  flake.modules.homeManager.git-gh =
    { lib, ... }:
    {
      programs.git = {
        enable = true;
        lfs.enable = true;

        settings = {
          alias = {
            st = "status";
            co = "checkout";
            ci = "commit";
            br = "branch";
            lg = "log --graph --oneline --decorate --all";
            unstage = "reset HEAD --";
            last = "log -1 HEAD";
            amend = "commit --amend --no-edit";
          };

          init.defaultBranch = "main";
          core = {
            editor = "nano";
            excludesFile = "~/.config/git/ignore";
          };
          diff.colorMoved = "default";
          merge.conflictstyle = "diff3";
          rerere.enabled = true;
          pull.rebase = false;
          push.autoSetupRemote = true;
        };
      };

      home.activation.provisionGitGlobalIgnore = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        target="$HOME/.config/git/ignore"
        source=${lib.escapeShellArg (toString gitIgnoreSource)}

        $DRY_RUN_CMD mkdir -p "$(dirname "$target")"

        if [ -L "$target" ] || [ ! -f "$target" ] || ! cmp -s "$source" "$target"; then
          $DRY_RUN_CMD rm -f "$target"
          $DRY_RUN_CMD cp "$source" "$target"
          $DRY_RUN_CMD chmod 0644 "$target"
        fi
      '';

      programs.gh = {
        enable = true;
        settings = {
          git_protocol = "ssh";
          editor = "nano";
        };
      };
    };
}
