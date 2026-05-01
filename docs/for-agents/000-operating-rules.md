# Operating Rules for Agents

Hard constraints. Follow these exactly.

## 1. Never commit private data

Files under `private/users/*/` and `private/hosts/*/` are gitignored.
Do not read, create, or reference them in tracked files.
The public safety check runs as part of `run-validation-gates.sh` (rule 4).

## 2. Options belong in feature owners, top-level facts, or the narrow tracked user owner only

Option declarations (`options.custom.*`, `options.host.*`) live only in
`modules/features/`, `modules/nixos.nix`, or the narrow tracked user owner when
it owns the canonical user identity fact. Never declare options in
`hardware/`, `private/`, or other locations.

## 3. No hardcoded usernames in tracked files

Tracked runtime should use the repo-wide `username` fact directly where
lower-level NixOS state genuinely needs one concrete user. Feature modules
should consume narrow top-level facts such as `config.username` or existing
lower-level state, never by hardcoding real usernames in tracked files.

## 4. Validation gates must pass

Before committing, run:

```bash
./scripts/run-validation-gates.sh
```

For structural changes, also run:

```bash
nix eval .#nixosConfigurations.predator.config.system.build.toplevel.drvPath
```

## 5. Dendritic top-level pattern only

All new feature modules must remain top-level dendritic modules. Publish
lower-level NixOS/Home Manager modules under `flake.modules.*`:

```nix
{ ... }: { flake.modules.nixos.my-feature = { config, lib, ... }: { ... }; }
```

Never turn `modules/features/` files into raw entry-point configs or `specialArgs`
plumbing.

## 6. Home Manager wiring happens in host composition

User-owned and host-aware HM modules are both published at the top level under
`flake.modules.homeManager.*`. Hosts own the concrete wiring into
`home-manager.users.<userName>.imports`. Host-aware lower-level modules should
capture direct flake inputs from the owning top-level module or read narrow
facts such as `config.username`, not build a repo-local carrier object.

## 7. host-specific hardware stays in hardware/

Machine-specific config (hardware-configuration.nix, disko.nix, boot,
device-specific quirks, TPM/LUKS, persistence/reset) lives in `hardware/<name>/`.
Package overlays and other host software policy do not belong there. If config
is reusable across hosts, promote it to a published lower-level module in
`modules/features/`.

## 8. Keep commits focused

One logical change per commit. Use the commit strategy:

- `fix(scope): description` for bug fixes
- `feat(scope): description` for new features
- `refactor(scope): description` for reorganization
- `chore: description` for housekeeping

## 9. Use active vs archived agent docs correctly

- Active execution plans live in `docs/for-agents/plans/`.
- Active progress logs live in `docs/for-agents/current/`.
- Keep those directories small: scaffolds plus genuinely active work only.
- Completed plans move to `docs/for-agents/archive/plans/`.
- Completed log tracks move to `docs/for-agents/archive/log-tracks/`.
- Audit and diagnostic reports go to `docs/for-agents/archive/reports/`.
- Use the tracked scaffolds when creating new docs:
  - `docs/for-agents/plans/000-plan-scaffold.md`
  - `docs/for-agents/current/000-log-track-scaffold.md`
