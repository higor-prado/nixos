# AGENTS.md

## Boot order — read these first
1. `docs/for-agents/000-operating-rules.md`
2. `docs/for-agents/001-repo-map.md`
3. `docs/for-agents/002-architecture.md`
4. `docs/for-agents/003-module-ownership.md`
5. `docs/for-agents/004-private-safety.md`
6. `docs/for-agents/005-validation-gates.md`
7. `docs/for-agents/006-extensibility.md`
8. `docs/for-agents/007-option-migrations.md`
9. `docs/for-agents/999-lessons-learned.md`

## Architecture (so you don't guess wrong)
- **Dendritic pattern on `flake-parts` + `import-tree`.** All `modules/**/*.nix` (except `_`-prefixed files) are auto-imported as top-level modules. Files prefixed with `_` are skipped — use them for feature-private helpers/data.
- **No `specialArgs` / `extraSpecialArgs`.** Publish values at the top level via `flake.modules.nixos.*` / `flake.modules.homeManager.*` and consume through `config.flake.modules.*`, narrow top-level facts, or existing lower-level state.
- **New files under `modules/` must be `git add`-ed before `nix eval`.** Auto-import only sees tracked files.
- **Feature modules publish one or both of** `flake.modules.nixos.<name>` and `flake.modules.homeManager.<name>`. Host composition in `modules/hosts/<host>.nix` imports them explicitly.
- **`hardware/<host>/`** owns only machine-specific hardware, disko, boot, persistence/reset. Package policy and software do NOT belong there.

## Hosts
| Host | Arch | Role |
|------|------|------|
| `predator` | `x86_64-linux` | Desktop (Hyprland) |
| `aurelius` | `aarch64-linux` | Server (VM) |
| `cerebelo` | `aarch64-linux` | Server (Orange Pi 5 RK3588S) |

## Validation — what to run and when
- **Before any commit:** `./scripts/run-validation-gates.sh`
- **Changed-file-only quality (shellcheck + nix parse):** `./scripts/check-changed-files-quality.sh [origin/main]`
- **Full (structure + all host stages):** `./scripts/run-validation-gates.sh all`
- **Single host eval/build:** `./scripts/run-validation-gates.sh predator`
- **Structure only (static checks, <2 min):** `./scripts/run-validation-gates.sh structure`

The gate runner invokes these per-host checks:
```
nix flake metadata
nix eval path:$PWD#nixosConfigurations.predator.config.system.stateVersion
nix eval path:$PWD#nixosConfigurations.predator.config.home-manager.users.<user>.home.stateVersion
nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.<user>.home.path
nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel
```

## Safety rules
1. **Never commit real private files** under `private/users/` or `private/hosts/`. Only `*.example` files are tracked. Pre-commit hook runs `check-repo-public-safety.sh`.
2. **Never hardcode usernames in tracked files.** Use `config.username`.
3. **No `openssh.authorizedKeys.keys` in tracked files.** Private overrides only.

## Docs organization
1. Root `docs/for-agents/` — only critical operating docs (000–009 and 999).
2. Agent docs use three-digit prefix NNN-name.md. Keep numbering stable.
3. Active plans → `docs/for-agents/plans/`, active logs → `docs/for-agents/current/`.
4. Completed work → `docs/for-agents/archive/{plans,log-tracks,reports}/`.

## Script boundary
- Repo `scripts/` — shared validation/safety tooling.
- Private/host-specific ops scripts → `~/ops/nixos-private-scripts/bin`.
- Shared aux scripts (`audit-system-up-to-date.sh`, `new-host-skeleton.sh`, etc.) are tracked but not part of the gate runner.

## Commit format
`fix(scope):`, `feat(scope):`, `refactor(scope):`, `chore:`

## Mutable copy-once configs
Files like `waybar`, `waypaper`, `walker`, `rmpc`, `mpd` configs are provisioned as mutable copy-once. Parity checks can fail when local runtime files intentionally diverge from templates.

## ⚠ RULE 999 — you own the whole repo
When a validation gate, test, or eval fails — even if the failure predates your task — do **not** label it "pre-existing" and move on. You are responsible for the entire repository, not only the change you are currently making.

Stop. Report the failure. Ask: *"I found this failure — is it known? Do you want me to fix it now or track it separately?"* Wait for explicit direction. Do not fix it unilaterally, but do not pretend it is not there.
