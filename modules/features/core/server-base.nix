{ den, ... }:
{
  den.aspects.server-base.nixos =
    { lib, ... }:
    {
      users.mutableUsers = true;
      services.getty.autologinUser = lib.mkForce null;
      documentation.enable = false;
      custom.ssh.settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
      };
    };
}
