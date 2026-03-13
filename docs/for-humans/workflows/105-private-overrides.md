# Private Overrides

## Set your real username

In the gitignored host private override entry point. For shape, see
`hardware/aurelius/private.nix.example`:

```nix
{ lib, ... }:
{
  # custom.user.name is now compatibility-only. Use it only when your
  # lower-level private host config still needs one selected local operator
  # account.
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
For shape, see `private/higorprado.nix.example`:

```nix
{ ... }:
{
  # Personal git config, theme paths, etc.
}
```

## Examples

See `*.nix.example` files for the expected shape without real values.
