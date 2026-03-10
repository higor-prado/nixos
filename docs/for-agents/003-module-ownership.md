# Module Ownership Boundaries

## Who owns what

| Location | Owns |
|----------|------|
| `modules/features/**/*.nix` | Feature behavior, NixOS + HM config, option declarations |
| `modules/desktops/*.nix` | Desktop compositions (aspect includes only) |
| `modules/hosts/*.nix` | Host composition (includes list + host wiring) |
| `hardware/<name>/` | Machine-specific hardware, boot, disks |
| `modules/features/core/home-manager-settings.nix` | HM framework settings (useGlobalPkgs, extraSpecialArgs, sharedModules) |
| `modules/users/<user>.nix` | User account (nixos) and base HM config (homeManager) |
| `home/base/private.nix.example` | Tracked example for the gitignored local user override entry point imported by the user aspect |
| `modules/features/core/user-context.nix` | `custom.user.name` contract |
| `modules/features/core/host-contracts.nix` | `custom.host.role` contract |

## Boundary rules

1. **Option declarations only in `modules/features/`** — enforced by
   `scripts/check-option-declaration-boundary.sh`.

2. **Hardware config only in `hardware/<name>/`** — NVIDIA driver, disk layout,
   TPM/LUKS, boot loader settings belong here, not in features.

3. **Reusable config belongs in features** — if a host setting could apply to
   other hosts, promote it to a den aspect.

4. **`environment.systemPackages` not in `hardware/<name>/default.nix`** — use
   software profile/pack overrides instead.

5. **No hardcoded usernames in tracked `.nixos` blocks** — prefer den `{ host, user }`
   context or user aspects. `custom.user.name` is compatibility-only, not the
   default feature wiring path.

6. **`openssh.authorizedKeys.keys` not tracked** — must be in an untracked private override file (see the tracked `*.nix.example` files for shape).

## Feature module checklist

When creating a new feature module:
- [ ] File is in `modules/features/<category>/`
- [ ] NixOS config in `den.aspects.<name>.nixos = ...`
- [ ] HM config in `den.aspects.<name>.homeManager = ...` (NOT via `hasHomeManagerUsers` guard)
- [ ] No `mkIf` for role/context checks — feature inclusion in a host IS the condition
- [ ] `mkIf` only for actual NixOS option value checks (e.g. `lib.mkIf config.services.foo.enable`)
- [ ] Custom options declared by the narrow owner module or the feature that reads them
- [ ] Added to host `includes` list in `modules/hosts/<host>.nix`
