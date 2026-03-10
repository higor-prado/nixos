{
  stdenv,
  kernel,
  fetchFromGitHub,
}:

stdenv.mkDerivation {
  pname = "linuwu-sense";
  version = "unstable-2026-03-09";

  src = fetchFromGitHub {
    owner = "0x7375646F";
    repo = "Linuwu-Sense";
    # Pin upstream instead of floating on main so source/hash changes do not
    # silently break the system on unrelated upstream pushes.
    rev = "66212aecd1fd66ae430111bda5d044df6602b89e";
    hash = "sha256-6adl5xghbEV0atUSTa9ucmoYm2UyozoDrA0Gt361xKY=";
  };

  nativeBuildInputs = kernel.moduleBuildDependencies;

  postPatch = ''
    # Upstream commit cc0885686871753c2040bf76a4bc0643055d335a appends an
    # interactive/sudo-based signing step to the build target. Kernel modules
    # in Nix builds must stay non-interactive and sandbox-safe.
    sed -i '/# --- auto sign block ---/,/# --- end auto sign block ---/d' Makefile
  '';

  makeFlags = [
    "KERNELRELEASE=${kernel.modDirVersion}"
    "KDIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
    "INSTALL_MOD_PATH=$(out)"
  ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/modules/${kernel.modDirVersion}/extra
    find . -name "*.ko" -exec cp {} $out/lib/modules/${kernel.modDirVersion}/extra/ \;
    runHook postInstall
  '';
}
