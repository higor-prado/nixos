{ den, ... }:
{
  den.aspects.user-context = den.lib.parametric {
    nixos =
      { lib, ... }:
      {
        options.custom.user.name = lib.mkOption {
          type = lib.types.str;
          default = "user";
          description = "Compatibility username bridge. Derived from the sole declared den host user by default; private overrides may still mkForce it when lower-level host config needs one selected local operator account.";
        };
      };

    includes = [
      (den.lib.take.exactly (
        { host, ... }:
        let
          userNames = builtins.attrNames host.users;
          declaredCount = builtins.length userNames;
          primaryUser =
            if declaredCount > 0 then builtins.elemAt userNames 0 else "user";
        in
        {
          nixos =
            { config, lib, ... }:
            {
              config = {
                assertions = [
                  {
                    assertion = declaredCount > 0;
                    message = "Host '${host.name}' must declare at least one user under den.hosts.${host.system}.${host.name}.users";
                  }
                  {
                    assertion = declaredCount == 1;
                    message = "Host '${host.name}' must declare exactly one tracked primary user while custom.user.name remains a compatibility bridge";
                  }
                  {
                    assertion = config.custom.user.name != "user" && config.custom.user.name != "" && config.custom.user.name != "root";
                    message = ''
                      custom.user.name resolved to an unsafe compatibility value (${config.custom.user.name}).
                      Keep the bridge derived from the sole tracked host user or override it privately with a real operator username.
                    '';
                  }
                ];

                custom.user.name = lib.mkDefault primaryUser;
              };
            };
        }
      ))
    ];
  };
}
