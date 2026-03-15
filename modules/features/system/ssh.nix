{ ... }:
{
  den.aspects.ssh = {
    nixos =
      { config, lib, ... }:
      {
        options.custom.ssh.settings = lib.mkOption {
          type = lib.types.attrsOf (lib.types.oneOf [
            lib.types.bool
            lib.types.int
            lib.types.str
          ]);
          default = { };
          description = "Host-specific OpenSSH settings merged over SSH feature defaults.";
        };

        config.services.openssh = {
          enable = true;
          settings = {
            PermitRootLogin = "no";
            PasswordAuthentication = false;
          } // config.custom.ssh.settings;
        };
      };

    homeManager =
      { ... }:
      {
        programs.ssh = {
          enable = true;
          enableDefaultConfig = false;
          includes = [
            "~/.ssh/config.local"
            "~/.ssh/config.d/*"
          ];
          matchBlocks."*" = {
            compression = false;
            forwardAgent = false;
            forwardX11 = false;
            hashKnownHosts = true;
            controlMaster = "auto";
            controlPath = "~/.ssh/controlmasters/%r@%h:%p";
            controlPersist = "10m";
            extraOptions = {
              ServerAliveInterval = "60";
              ServerAliveCountMax = "3";
              KexAlgorithms = "curve25519-sha256@libssh.org,ecdh-sha2-nistp521,ecdh-sha2-nistp384,ecdh-sha2-nistp256,diffie-hellman-group-exchange-sha256";
              MACs = "hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,umac-128-etm@openssh.com,hmac-sha2-512,hmac-sha2-256";
              HostKeyAlgorithms = "ssh-ed25519-cert-v01@openssh.com,ssh-ed25519,ecdsa-sha2-nistp521-cert-v01@openssh.com,ecdsa-sha2-nistp384-cert-v01@openssh.com,ecdsa-sha2-nistp256-cert-v01@openssh.com,ecdsa-sha2-nistp256";
            };
          };
        };
      };
  };
}
