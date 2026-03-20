# Private Overrides

## Set your real username

In the gitignored host private override entry point. For shape, see
`private/hosts/aurelius/default.nix.example`:

```nix
{ lib, ... }:
{
  # Override the selected tracked user only when the real local operator
  # account differs from the tracked default.
  custom.user.name = lib.mkForce "your-real-username";
}
```

## Add SSH keys

In the same gitignored host private override entry point:

```nix
users.users.your-real-username.openssh.authorizedKeys.keys = [
  "ssh-ed25519 AAAA... your-key"
];
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
