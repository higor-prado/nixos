# Private Overrides

## What goes in private overrides

Real-world settings that must never be committed:
- SSH authorized keys
- Personal dotfile paths
- Theme/font preferences
- Host-local secrets and machine-specific auth material
- Host-private service endpoints and public keys that are safe to share
  operationally but should not be hardcoded into the tracked runtime

## Location

All private overrides now live under one top-level `private/` root. The tracked
example files show the expected shape without requiring the real private files
to exist in the repo:

```
private/hosts/predator/default.nix   # host-level private config
private/users/higorprado/default.nix # home-manager private config
```

Tracked example files show the expected shape without real values:

- `private/hosts/predator/default.nix.example`
- `private/hosts/aurelius/default.nix.example`
- `private/users/higorprado/default.nix.example`

Examples may also include host-private service wiring such as:
- Attic consumer endpoint/public key for `predator`
- Attic publisher endpoint/cache/token file for `predator`
- Host-local advertised service URLs for `aurelius`
- GitHub runner repository binding and token file for `aurelius`

## Priority

Private config uses `lib.mkForce` or higher-priority `mkOverride` to take
precedence over tracked defaults. The tracked runtime already owns the
canonical `username` fact. Private overrides are only for genuinely local
details such as SSH keys, secret values, or host-local user attr paths that
must not be tracked.

## Gitignore

The `.gitignore` patterns for `private/users/**` and `private/hosts/**` ensure
private files are never accidentally committed.

## Safety

Run `./scripts/check-repo-public-safety.sh` before any commit to verify no
private data is tracked.
