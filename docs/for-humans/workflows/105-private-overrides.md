# Private Overrides

## Set host-private user state

If a gitignored host private override needs to target a concrete local user
attr path, bind that host-local username there. This is private host wiring,
not the tracked runtime's canonical `username` fact. For shape, see
`private/hosts/aurelius/default.nix.example`:

```nix
{ ... }:
let
  userName = "your-real-username";
in
{
  users.users.${userName}.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAA... your-key"
  ];
}
```

## Add SSH keys

In the same gitignored host private override entry point, add
`users.users.${userName}.openssh.authorizedKeys.keys` under the same concrete
user definition shown above.

## Host-private service wiring

If a host needs deployment-specific service facts that must not be hardcoded in
tracked runtime, place them in the gitignored host private override. For shape,
see `private/hosts/predator/services.nix.example` and
`private/hosts/aurelius/services.nix.example`:

```nix
{ ... }:
{
  nix.settings = {
    extra-substituters = [ "http://aurelius.example.ts.net:8080/aurelius" ];
    extra-trusted-public-keys = [ "aurelius:replace-with-public-key" ];
  };

  environment.etc."attic/publisher.conf" = {
    mode = "0400";
    text = ''
      ENDPOINT=http://aurelius.example.ts.net:8080
      CACHE=aurelius
      TOKEN_FILE=/home/<user>/.config/attic/predator-publisher.token
    '';
  };

  services.github-runners.aurelius = {
    url = "https://github.com/owner-or-organization";
    tokenFile = "/home/<user>/.config/github-runner/aurelius.token";
    runnerGroup = "Default";
  };
}
```

Important:
- `services.github-runners.aurelius.tokenFile` is read on the target host
- `TOKEN_FILE` inside `/etc/attic/publisher.conf` is read on the host that publishes
- for an org-wide runner, the working shape is organization URL plus
  `runnerGroup = "Default"`
- if the repositories are public, the GitHub runner group must allow public
  repositories

WireGuard concrete tunnel facts follow the same rule: put them in the gitignored
host-private networking overrides using real lower-level NixOS options such as
`networking.wg-quick.interfaces.*` and `networking.nat.*`. For shape, see:
- `private/hosts/aurelius/networking.nix.example`
- `private/hosts/predator/networking.nix.example`

## Home-manager private config

In the gitignored home private override entry point (imported if it exists).
For shape, see `private/users/higorprado/default.nix.example`:

```nix
{ ... }:
{
  # Personal git config, theme paths, etc.
}
```

## Examples

See tracked `*.example` files for the expected shape without real values.
