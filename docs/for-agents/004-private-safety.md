# Private Safety

## Never read or track these files

- `private/users/*/*.nix`
- `private/users/*/*/*.nix`
- `private/hosts/*/*.nix`
- `private/hosts/*/*/*.nix`

These are gitignored and contain real usernames, SSH keys, and personal paths.

## Before committing: run the safety check

```bash
./scripts/check-repo-public-safety.sh
```

This script checks that no private data (real usernames, SSH keys,
email addresses, IP addresses outside approved ranges) appears in tracked files.

## The tracked-user pattern

Tracked host modules declare their tracked user under
`repo.hosts.<host>.trackedUsers`. In this personal repo, the generator and the
tracked real hosts use the canonical `higorprado` user module by default.
`custom.user.name` is derived from that sole declared host user by default. The
real username may still be set in `private/hosts/<host>/default.nix` with
`lib.mkForce` when needed.

Compatibility-only consumers may still reference the bridge dynamically:
```nix
let userName = config.custom.user.name; in ...
```

Tracked runtime wiring should prefer `config.repo.context.userName`. The bridge
exists so gitignored host-private overrides can still select a concrete local
operator account when needed.

## Hardcoded home paths

Default rule:

- do not introduce new hardcoded `"/home/username"` paths in tracked files
- use `config.home.homeDirectory` in HM modules where possible
- use the tracked-user helper/context in NixOS modules when one selected user is needed
- reserve `config.custom.user.name` for compatibility-only lower-level wiring

Current state:

- there is no live tracked hardcoded home-path exception in module code
- historical docs/progress logs may still mention old concrete paths as part of
  recorded migration history

If a new tracked hardcoded home path is ever reintroduced, document the reason
explicitly here and make the public-safety allowlist change intentional.
