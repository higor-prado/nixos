{
  lib,
  stdenvNoCC,
  src,
}:

stdenvNoCC.mkDerivation {
  pname = "catppuccin-zen-browser";
  version = "unstable-2025-09-28";

  inherit src;

  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
    cp -r themes "$out/themes"
    runHook postInstall
  '';

  meta = with lib; {
    description = "Official Catppuccin Zen Browser CSS theme assets";
    homepage = "https://github.com/catppuccin/zen-browser";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
