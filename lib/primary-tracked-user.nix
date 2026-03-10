{ lib }:
let
  trackedUserNames = host: builtins.attrNames host.users;

  primaryTrackedUserName =
    host:
    let
      userNames = trackedUserNames host;
      declaredCount = builtins.length userNames;
    in
    if declaredCount == 1 then
      builtins.elemAt userNames 0
    else
      throw ''
        Host '${host.name}' must declare exactly one tracked user to resolve a primary tracked user.
        Got ${toString declaredCount}: ${lib.concatStringsSep ", " userNames}
      '';
in
{
  inherit trackedUserNames primaryTrackedUserName;
}
