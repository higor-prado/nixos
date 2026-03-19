{ ... }:
{
  den.aspects.desktop-base = {
    provides.to-users.homeManager =
      { ... }:
      {
        xdg.enable = true;
        xdg.mimeApps.enable = true;
        xdg.userDirs = {
          enable = true;
          desktop = "$HOME/Desktop";
          download = "$HOME/Downloads";
          templates = "$HOME/Templates";
          publicShare = "$HOME/Public";
          documents = "$HOME/Documents";
          music = "$HOME/Music";
          pictures = "$HOME/Pictures";
          videos = "$HOME/Videos";
        };
      };
  };
}
