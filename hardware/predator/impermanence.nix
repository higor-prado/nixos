{ ... }:
let
  persistedPaths = import ./persisted-paths.nix;
in
{
  # Persistent storage must be mounted early because it carries machine identity,
  # network profiles, SSH host keys, and other system state required during boot.
  fileSystems."/persist".neededForBoot = true;

  environment.persistence."/persist" = {
    hideMounts = true;
    directories = persistedPaths.directories;
    files = persistedPaths.files;
  };
}
