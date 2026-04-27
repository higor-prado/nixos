# Module Ownership Boundaries

## Who owns what

| Location | Owns |
|----------|------|
| `modules/features/**/*.nix` | Feature behavior, published lower-level NixOS/HM modules, option declarations |
| `modules/desktops/*.nix` | Desktop composition lower-level modules |
| `modules/hosts/*.nix` | Host owner files, concrete configuration declarations, machine-specific operator wiring, and host-only user entitlements |
| `modules/nixos.nix` | Top-level structural NixOS runtime surface |
| `modules/flake-parts.nix` | Enables the `flake.modules.*` surface |
| `hardware/<name>/` | Machine-specific hardware, boot, disks, persistence/reset |
| `modules/features/core/home-manager-settings.nix` | HM framework settings |
| `modules/users/<user>.nix` | User account (nixos), base HM config (homeManager), repo-wide primary-user semantics, and user-owned facts such as `username` when they are truly that user's identity |
| `private/users/higorprado/default.nix.example` | Tracked example for the gitignored local user override entry point imported by the user runtime module |

## Boundary rules

1. **Option declarations only in `modules/features/`, `modules/nixos.nix`, or the narrow tracked user owner that really owns the fact** — enforced by
   `scripts/check-option-declaration-boundary.sh`.

2. **Hardware config only in `hardware/<name>/`** — NVIDIA driver, disk layout,
   TPM/LUKS, boot loader settings, persistence, and storage-reset logic belong
   here, not in features.

3. **Reusable config belongs in features** — if a host setting could apply to
   other hosts, promote it to a published lower-level module in `modules/features/`.

4. **Software policy does not belong in `hardware/` unless it is directly part
   of the machine support surface** — package overlays and unrelated runtime
   policy stay out of `hardware/`. Keep `environment.systemPackages` out of
   `hardware/<name>/default.nix`.

5. **Package ownership follows machine owner vs user owner**
   - Prefer **NixOS** for machine-owned/runtime-owned packages: services,
     boot/session plumbing, drivers, fonts, firewall/network support,
     containers, PAM, `/etc` payloads, and tools that must exist independent of
     any user home.
   - Prefer **Home Manager** for user-interactive packages: CLI tools, GUI apps,
     editors, prompts, terminals, themes, user-local helpers, and tools whose
     main consumer is the tracked user inside a login session.
   - If one capability spans both concerns, **split the feature** and publish
     both `flake.modules.nixos.*` and `flake.modules.homeManager.*` owners.
   - Do not use `environment.systemPackages` as a catch-all for "tools wanted on
     this host" when the real owner is the user environment.

6. **No hardcoded usernames in tracked `.nixos` blocks** — prefer narrow facts
   such as `config.username`, existing lower-level state, or the tracked
   user runtime module.

7. **`openssh.authorizedKeys.keys` not tracked** — must be in an untracked private override file (see the tracked `*.nix.example` files for shape).

## Package ownership examples

### NixOS-owned examples

- `modules/features/system/audio.nix` — PipeWire and realtime audio support
- `modules/features/system/networking-wireguard-client.nix` — machine VPN behavior
- `modules/features/desktop/packages-fonts.nix` — machine-wide fonts
- `modules/desktops/hyprland-standalone.nix` — Hyprland desktop composition substrate
- `modules/features/desktop/regreet.nix` — ReGreet greetd greeter (Hyprland)

### Home Manager-owned examples

- `modules/features/shell/core-user-packages.nix` — user CLI tool set
- `modules/features/desktop/desktop-apps.nix` — user desktop app choices
- `modules/features/dev/dev-tools.nix` — user development workflow tools
- `modules/features/desktop/theme-base.nix` — user theme and UI preferences

### Split ownership examples

- `modules/features/shell/fish.nix` — NixOS owns base shell availability; HM owns user UX
- `modules/features/system/ssh.nix` — NixOS owns the daemon; HM owns client config
- `modules/features/desktop/hyprland.nix` — NixOS owns compositor/runtime pieces; HM owns session bootstrap and user config materialization
- `modules/features/dev/editor-neovim.nix` — NixOS owns PAM/session limits; HM owns editor package and user config

## Feature module checklist

When creating a new feature module:
- [ ] File is in `modules/features/<category>/`
- [ ] NixOS config is published in `flake.modules.nixos.<name> = ...` when needed
- [ ] Home Manager config is published in `flake.modules.homeManager.<name> = ...` when needed
- [ ] Host-aware feature logic reads narrow top-level facts, existing lower-level state, or direct flake inputs captured by the owner
- [ ] No `mkIf` for role/context checks — feature inclusion in a host IS the condition
- [ ] `mkIf` only for actual NixOS option value checks (e.g. `lib.mkIf config.services.foo.enable`)
- [ ] Custom options declared by the narrow owner module or the feature that reads them
- [ ] If universal (must be on every host): add to each concrete host module that owns canonical imports
- [ ] If host-specific: add to that host's explicit NixOS/HM import lists in `modules/hosts/<host>.nix`
