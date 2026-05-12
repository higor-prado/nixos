{ inputs, ... }:
{
  flake.modules.homeManager.editors-zed =
    { pkgs, ... }:
    let
      zedPackage = inputs.zed.packages.${pkgs.stdenv.hostPlatform.system}.default;
    in
    {
      home.packages = [ zedPackage ];

      programs.fish.shellAbbrs = {
        zed = "uwsm-app zeditor";
        zeditor = "uwsm-app zeditor";
      };
    };
}
