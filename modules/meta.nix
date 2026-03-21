{ lib, ... }:
{
  options.username = lib.mkOption {
    type = lib.types.str;
    readOnly = true;
    default = "higorprado";
    description = "Canonical tracked user name for repo-owned user modules.";
  };
}
