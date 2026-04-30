{ config, ... }:
{
  flake.modules.nixos.greetd =
    { pkgs, ... }:
    let
      tuigreet = "${pkgs.tuigreet}/bin/tuigreet";
    in
    {
      services.greetd = {
        enable = true;
        settings = {
          default_session = {
            command = "${tuigreet} --time --remember --remember-session --asterisks --cmd start-hyprland";
            user = "greeter";
          };
        };
      };
    };
}
