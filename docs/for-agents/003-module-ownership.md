# Module Ownership Boundaries

## Who owns what

| Location | Owns |
|----------|------|
| `modules/features/**/*.nix` | Feature behavior, published lower-level NixOS/HM modules, option declarations |
| `modules/desktops/*.nix` | Desktop composition lower-level modules |
| `modules/hosts/*.nix` | Host inventory plus concrete configuration declarations |
| `modules/options/*.nix` | Top-level runtime surfaces, inventory schema, and runtime contracts |
| `hardware/<name>/` | Machine-specific hardware, boot, disks |
| `modules/features/core/home-manager-settings.nix` | HM framework settings |
| `modules/users/<user>.nix` | User account (nixos) and base HM config (homeManager) |
| `private/users/higorprado/default.nix.example` | Tracked example for the gitignored local user override entry point imported by the user runtime module |
| `modules/options/repo-runtime-contracts.nix` | Runtime contracts for `custom.user.name`, `custom.host.role`, and repo context |

## Boundary rules

1. **Option declarations only in `modules/features/` or `modules/options/`** — enforced by
   `scripts/check-option-declaration-boundary.sh`.

2. **Hardware config only in `hardware/<name>/`** — NVIDIA driver, disk layout,
   TPM/LUKS, boot loader settings belong here, not in features.

3. **Reusable config belongs in features** — if a host setting could apply to
   other hosts, promote it to a published lower-level module in `modules/features/`.

4. **`environment.systemPackages` not in `hardware/<name>/default.nix`** — use
   software profile/pack overrides instead.

5. **No hardcoded usernames in tracked `.nixos` blocks** — prefer runtime
   context from `config.repo.context.*` or the tracked user runtime module.
   `custom.user.name` is compatibility-only, not the default feature wiring path.

6. **`openssh.authorizedKeys.keys` not tracked** — must be in an untracked private override file (see the tracked `*.nix.example` files for shape).

## Feature module checklist

When creating a new feature module:
- [ ] File is in `modules/features/<category>/`
- [ ] NixOS config is published in `flake.modules.nixos.<name> = ...` when needed
- [ ] Home Manager config is published in `flake.modules.homeManager.<name> = ...` when needed
- [ ] Host-aware feature logic reads host/user data through `config.repo.context.*`
- [ ] No `mkIf` for role/context checks — feature inclusion in a host IS the condition
- [ ] `mkIf` only for actual NixOS option value checks (e.g. `lib.mkIf config.services.foo.enable`)
- [ ] Custom options declared by the narrow owner module or the feature that reads them
- [ ] If universal (must be on every host): add to each concrete host module that owns canonical imports
- [ ] If host-specific: add to that host's explicit NixOS/HM import lists in `modules/hosts/<host>.nix`
