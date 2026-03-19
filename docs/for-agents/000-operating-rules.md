# Operating Rules for Agents

Hard constraints. Follow these exactly.

## 1. Never commit private data

Files under `private/users/*/` and `private/hosts/*/` are gitignored.
Do not read, create, or reference them in tracked files.
Run `./scripts/check-repo-public-safety.sh` before committing.

## 2. Options belong in modules/features/ only

Option declarations (`options.custom.*`, `options.host.*`) live only in
`modules/features/` files. Never declare options in `hardware/`, `home/`,
or other locations.

## 3. No hardcoded usernames in tracked files

Tracked hosts must declare their safe fallback user under
`den.hosts.<system>.<host>.users` in the host module. `custom.user.name` is a
derived compatibility bridge that may still be `mkForce`-overridden in private
files. Tracked feature modules should prefer the narrowest correct den context
shape: owned `homeManager` when no host/user data is needed, `{ host }` when
only host data is needed, and `{ host, user }` only for genuinely user-specific
logic. Never hardcode real usernames in tracked files.

## 4. Validation gates must pass

Before committing, run:
```bash
./scripts/run-validation-gates.sh
```

For structural changes, also run:
```bash
nix eval .#nixosConfigurations.predator.config.system.build.toplevel.drvPath
```

## 5. Den aspect pattern only

All new NixOS feature modules must use the den aspect pattern:
```nix
{ ... }: { den.aspects.my-feature.nixos = { config, lib, ... }: { ... }; }
```

Never use raw `imports` lists in `modules/features/`.

## 6. Home-manager routing depends on ownership

User-owned Home Manager config belongs in
`den.aspects.<name>.homeManager = { ... }: { ... };`.
Den routes that class to `home-manager.users.<userName>` for hosts whose
tracked users declare `classes = [ "homeManager" ]`.

Host-owned Home Manager config is different in current `den`: a host aspect's
top-level `.homeManager` is not routed to users automatically. Host-to-user HM
must go through explicit mutual routing with `den._.mutual-provider`, declared
via `provides.to-users.homeManager = ...` or `provides.<user>.homeManager = ...`,
and then aggregated at the host's `_.to-users` surface.

Do not hand-wire `home-manager.users.<userName>` from feature modules and do
not create separate top-level home-manager feature modules.

## 7. host-specific hardware stays in hardware/

Machine-specific config (hardware-configuration.nix, disko.nix, NVIDIA drivers,
LUKS, boot loader) lives in `hardware/<name>/`. If config is reusable across
hosts, promote it to a den aspect in `modules/features/`.

## 8. Keep commits focused

One logical change per commit. Use the commit strategy:
- `fix(scope): description` for bug fixes
- `feat(scope): description` for new features
- `refactor(scope): description` for reorganization
- `chore: description` for housekeeping

## 9. Use active vs archived agent docs correctly

- Active execution plans live in `docs/for-agents/plans/`.
- Active progress logs live in `docs/for-agents/current/`.
- Completed plans move to `docs/for-agents/archive/plans/`.
- Completed log tracks move to `docs/for-agents/archive/log-tracks/`.
- Use the tracked scaffolds when creating new docs:
  - `docs/for-agents/plans/000-plan-scaffold.md`
  - `docs/for-agents/current/000-log-track-scaffold.md`
