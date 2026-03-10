{ ... }:
{
  den.aspects.git-gh = {
    homeManager =
      { ... }:
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
            core.editor = "nano";
            diff.colorMoved = "default";
            merge.conflictstyle = "diff3";
            rerere.enabled = true;
            pull.rebase = false;
            push.autoSetupRemote = true;
          };

          ignores = [
            "*.swp"
            "*.swo"
            "*~"
            ".DS_Store"
            ".envrc"
            "node_modules/"
            ".venv/"
            "__pycache__/"
            "*.pyc"
            ".direnv/"
            "result"
          ];
        };

        programs.gh = {
          enable = true;
          settings = {
            git_protocol = "ssh";
            editor = "nano";
          };
        };
      };
  };
}
