{ ... }:
{
  flake.modules.nixos.editors-zed =
    { pkgs, ... }:
    {
      programs.nix-ld.enable = true;
      programs.nix-ld.libraries = with pkgs; [
        stdenv.cc.cc.lib
        zlib
        openssl
      ];
    };

  flake.modules.homeManager.editors-zed =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.zed-editor ];

      programs.fish.shellAbbrs = {
        zed = "uwsm-app zeditor";
        zeditor = "uwsm-app zeditor";
      };
    };
}
