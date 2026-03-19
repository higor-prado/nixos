{ ... }:
{
  den.aspects.editor-emacs = {
    provides.to-users.homeManager =
      { config, pkgs, ... }:
      {
        programs.emacs = {
          enable = true;
          package = pkgs.emacs-pgtk;
        };

        home.sessionVariables = {
          DOOMDIR = "${config.xdg.configHome}/doom";
          EMACSDIR = "${config.xdg.configHome}/emacs";
          DOOMLOCALDIR = "${config.xdg.dataHome}/doom";
          DOOMPROFILELOADFILE = "${config.xdg.stateHome}/doom-profiles-load.el";
        };

        services.emacs = {
          enable = true;
          socketActivation.enable = true;
        };

        programs.fish.shellAbbrs = {
          emacs = "emacsclient -c -a ''";
          e = "emacsclient -c -a ''";
        };

        programs.fish.interactiveShellInit = ''
          if test -d "$HOME/.config/emacs/bin"
            fish_add_path "$HOME/.config/emacs/bin"
          end
        '';

        xdg.desktopEntries.emacs = {
          name = "Emacs";
          genericName = "Text Editor";
          exec = "emacsclient -c %F";
          icon = "emacs";
          type = "Application";
          terminal = false;
          categories = [
            "Development"
            "TextEditor"
          ];
          mimeType = [
            "text/english"
            "text/plain"
            "text/x-makefile"
            "text/x-c++hdr"
            "text/x-c++src"
            "text/x-chdr"
            "text/x-csrc"
            "text/x-java"
            "text/x-moc"
            "text/x-pascal"
            "text/x-tcl"
            "text/x-tex"
            "application/x-shellscript"
            "text/x-c"
            "text/x-c++"
          ];
        };
      };
  };
}
