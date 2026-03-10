{
  lib,
  rustPlatform,
  pkg-config,
  src,
}:

rustPlatform.buildRustPackage rec {
  pname = "dms-awww";
  version = "2.0.0";

  inherit src;

  cargoLock = {
    lockFile = "${src}/Cargo.lock";
  };

  nativeBuildInputs = [ pkg-config ];

  meta = with lib; {
    description = "Efficient wallpaper management for DMS using awww";
    homepage = "https://github.com/higorprado/dms-awww-integration";
    license = licenses.mit;
    mainProgram = "dms-awww";
    platforms = platforms.linux;
  };
}
