{ buildGoModule, fetchFromGitHub }:

buildGoModule {
  pname = "predator-tui";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "higorprado";
    repo = "predator-tui";
    rev = "main";
    sha256 = "sha256-luRM+nPfuYXtl4v3m4LAYZQEMuyR3lydaUBPBdlhWz0=";
  };

  vendorHash = "sha256-lKSr05aeK+HBxJKIbBPSesYpokf6D2Yol8p4OHHjNQ8=";
}
