# Private Safety

## Never read or track these files

- `private/users/*/*.nix`
- `private/users/*/*/*.nix`
- `private/hosts/*/*.nix`
- `private/hosts/*/*/*.nix`

These are gitignored and contain real usernames, SSH keys, and personal paths.

## Before committing: the safety check runs automatically

The public safety check is part of `run-validation-gates.sh structure` (rule 4).
It can also be run standalone:

```bash
./scripts/check-repo-public-safety.sh
```

This script checks that no private data (real usernames, SSH keys,
email addresses, IP addresses outside approved ranges) appears in tracked files.

## The tracked-user pattern

In this personal repo, the tracked runtime uses the canonical `username` fact
for the shared tracked user.

Tracked runtime consumers should reference that fact directly:

```nix
let userName = config.username; in ...
```

Tracked runtime wiring should prefer `config.username` when a lower-level module
truly needs the tracked user.

## Hardcoded home paths

Default rule:

- do not introduce new hardcoded `"/home/username"` paths in tracked files
- use `config.home.homeDirectory` in HM modules where possible
- use `config.username` in NixOS modules when one tracked user is needed

Current state:

- there is no live tracked hardcoded home-path exception in module code
- historical docs/progress logs may still mention old concrete paths as part of
  recorded migration history

If a new tracked hardcoded home path is ever reintroduced, document the reason
explicitly here and make the public-safety allowlist change intentional.

## Known limitation: `builtins.pathExists` + gitignored files in flake eval

The private override pattern (`hardware/<name>/default.nix`, `modules/users/<user>.nix`)
imports gitignored files via `builtins.pathExists`. During `nix eval .#...` or
`nix build .#...`, Nix copies only git-tracked files to the store, so
`pathExists` returns `false` and the override is silently skipped.

**Consequence:** if a tracked module `enable = true`s an option only defined in a
private override, `nix eval .#...` fails with "The option `...` was accessed but
has no value defined." This is a false positive — `nixos-rebuild` on the target
machine works because it evaluates from the local filesystem.

**Workaround:** accept the eval error for hosts with private-only bindings.
`nixos-rebuild` on the target machine is the correct validation.
