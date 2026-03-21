{ ... }:
{
  flake.modules.nixos.forgejo =
    { ... }:
    {
      services.forgejo = {
        enable = true;
        settings = {
          server = {
            HTTP_ADDR = "127.0.0.1";
            HTTP_PORT = 3000;
            DOMAIN = "127.0.0.1";
            ROOT_URL = "http://127.0.0.1:3000/";
            DISABLE_SSH = true;
          };

          service.DISABLE_REGISTRATION = true;
          repository.DEFAULT_PRIVATE = "private";
        };
      };
    };
}
