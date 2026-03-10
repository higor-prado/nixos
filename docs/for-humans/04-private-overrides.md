# Private Overrides

## What goes in private overrides

Real-world settings that must never be committed:
- Your actual username
- SSH authorized keys
- Personal dotfile paths
- Theme/font preferences

## Location

Each host and `home/base/` has a gitignored private override entry point:

```
hardware/predator/private.nix        # host-level private config
home/base/private.nix                # home-manager private config
```

Tracked example files show the expected shape without real values:

- `hardware/predator/private.nix.example`
- `home/base/private.nix.example`

## Priority

Private config uses `lib.mkForce` or higher-priority `mkOverride` to take
precedence over tracked defaults. The tracked host module declares its tracked
user under `den.hosts.<system>.<host>.users`, and `custom.user.name` is derived
from that by default. Most tracked feature wiring now uses den context directly;
your private override may still override `custom.user.name` when lower-level host
config needs one selected local operator account.

## Gitignore

The `.gitignore` patterns `home/*/private.nix` and `hardware/*/private.nix`
ensure private files are never accidentally committed.

## Safety

Run `./scripts/check-repo-public-safety.sh` before any commit to verify no
private data is tracked.
