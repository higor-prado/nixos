# Private Overrides

## What goes in private overrides

Real-world settings that must never be committed:
- Your actual username
- SSH authorized keys
- Personal dotfile paths
- Theme/font preferences

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
- `private/users/higorprado/default.nix.example`

## Priority

Private config uses `lib.mkForce` or higher-priority `mkOverride` to take
precedence over tracked defaults. The tracked runtime uses the canonical
`username` fact, and tracked lower-level modules should read that fact when one
concrete operator account is part of the runtime.

## Gitignore

The `.gitignore` patterns for `private/users/**` and `private/hosts/**` ensure
private files are never accidentally committed.

## Safety

Run `./scripts/check-repo-public-safety.sh` before any commit to verify no
private data is tracked.
