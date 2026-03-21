# Private Overrides

## Set host-private user state

In the gitignored host private override entry point, declare concrete user
state directly with the real local username. For shape, see
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

In the same gitignored host private override entry point:

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

See `*.nix.example` files for the expected shape without real values.
