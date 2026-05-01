{ ... }:
{
  flake.modules.homeManager.desktop-apps =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        teams-for-linux
        meld
        obsidian
        super-productivity
      ];
    };
}
