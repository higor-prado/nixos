{
  broken-with-duplicated-role = {
    role = "server";
    integrations = { };
  };

  broken-with-duplicated-system = {
    system = "x86_64-linux";
    integrations = { };
  };

  broken-with-deprecated-dendritic = {
    dendritic = {
      ssh = true;
      fish = true;
    };
    integrations = { };
  };

  broken-non-bool-integration = {
    integrations = {
      homeManager = "yes";
    };
  };

  broken-legacy-modules-field = {
    system = "x86_64-linux";
    role = "server";
    integrations = { };
    modules = [ "legacy-module.nix" ];
  };
}
