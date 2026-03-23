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
  custom.attic.client = {
    endpoint = "http://aurelius.example.ts.net:8080/aurelius";
    publicKey = "aurelius:replace-with-public-key";
  };

  custom.attic.publisher = {
    endpoint = "http://aurelius.example.ts.net:8080";
    cache = "aurelius";
    tokenFile = "/home/<user>/.config/attic/predator-publisher.token";
  };

  custom.githubRunner = {
    url = "https://github.com/owner-or-organization";
    tokenFile = "/home/<user>/.config/github-runner/aurelius.token";
    runnerGroup = "Default";
  };
}
```

Important:
- `custom.githubRunner.tokenFile` is read on the target host
- `custom.attic.publisher.tokenFile` is read on the host that publishes
- for an org-wide runner, the working shape is organization URL plus
  `runnerGroup = "Default"`
- if the repositories are public, the GitHub runner group must allow public
  repositories

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
