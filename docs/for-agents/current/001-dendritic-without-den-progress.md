# Dendritic Without Den Migration Progress

## Status

In progress

## Related Plan

- [002-dendritic-without-den-migration.md](/home/higorprado/nixos/docs/for-agents/plans/002-dendritic-without-den-migration.md)

## Baseline

- Working branch: `dendritic-without-den`
- Starting point: repo on commit `65692d6` on top of the post-`bidirectional`-removal `den` shape
- Current authoritative baseline:
  - `predator` system `stateVersion = 25.11`
  - `predator` HM `stateVersion = 25.11`
  - `predator` `custom.host.role = desktop`
  - `predator` `custom.user.name = higorprado`
  - `predator` HM package count = `141`
  - `predator` `programs.git.enable = true`
  - `predator` `programs.starship.enable = true`
  - `predator` HM out path = `/nix/store/9aqwfh74yvdnlwf6jqr1an6xirrgy423-home-manager-path`
  - `predator` system out path = `/nix/store/lbry9rp09m2690i5k0yqx9y1qz80lbla-nixos-system-predator-26.05.20260318.b40629e`
- Active objective: finish Phase 0 baseline and land the first Phase 1 skeleton

## Slices

### Slice 1

- Created the active plan and opened the execution branch
- Captured the parity baseline for the current authoritative `den` outputs
- Added a repo-local dendritic skeleton under `modules/options/`:
  - `flake-parts` lower-level module registry import
  - top-level `configurations.nixos` option
  - repo-owned `repo.hosts` / `repo.users` inventory
  - namespaced shadow outputs under `flake.dendritic.nixosConfigurations`
  - repo-owned lower-level context modules for the shadow path
- Dual-published host/user inventory in:
  - `modules/hosts/predator.nix`
  - `modules/hosts/aurelius.nix`
  - `modules/users/higorprado.nix`
- Corrected two mistakes during the slice:
  - moved option-owning files from `modules/framework/` to `modules/options/`
    to satisfy the repo boundary gate
  - moved shadow outputs out of canonical `flake.nixosConfigurations` into the
    `flake.dendritic` namespace so existing validation scripts keep treating
    only the real hosts as authoritative
- Validation:
  - `nix eval --raw path:$PWD#dendritic.nixosConfigurations.predator.config.system.stateVersion`
  - `nix eval --raw path:$PWD#dendritic.nixosConfigurations.predator.config.home-manager.users.higorprado.home.stateVersion`
  - `nix eval --raw path:$PWD#dendritic.nixosConfigurations.aurelius.config.system.stateVersion`
  - `./scripts/run-validation-gates.sh`
- Outcome:
  - shadow `dendritic` namespace evaluates for `predator` and `aurelius`
  - authoritative `den` validation path remains green

### Slice 2

- Added [repo-runtime-contracts.nix](/home/higorprado/nixos/modules/options/repo-runtime-contracts.nix)
  so the shadow path now owns its own lower-level runtime contracts and context
  bridge without relying on `den`
- Updated `modules/options/shadow-hosts.nix`
  so the shadow hosts now consume:
  - `hardwareImports`
  - `extraSystemPackages`
  - repo-owned `custom.host.role`
  - repo-owned `custom.user.name`
  - repo-owned `repo.context`
- Corrected two implementation mistakes in this slice:
  - lower-level host modules had mixed `config.*` assignments with top-level
    config attrs; fixed by moving the lower-level config into an explicit
    `config = { ... };` block
  - the temporary tmpfs/container fallback conflicted with real hardware imports;
    fixed by making it conditional only when a shadow host has no
    `hardwareImports`
- Validation:
  - `nix eval --raw path:$PWD#dendritic.nixosConfigurations.predator.config.custom.host.role`
  - `nix eval --raw path:$PWD#dendritic.nixosConfigurations.predator.config.custom.user.name`
  - `nix eval --raw path:$PWD#dendritic.nixosConfigurations.aurelius.config.custom.host.role`
  - `nix eval --raw path:$PWD#dendritic.nixosConfigurations.aurelius.config.custom.user.name`
  - `nix build --no-link --print-out-paths path:$PWD#dendritic.nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`
  - `nix build --no-link --print-out-paths path:$PWD#dendritic.nixosConfigurations.predator.config.system.build.toplevel`
  - `./scripts/run-validation-gates.sh`
- Outcome:
  - `predator` shadow now builds both system and HM
  - `predator` shadow exposes the same host/user compatibility bridge names as
    the authoritative path
  - `aurelius` shadow resolves runtime role and user bridge values
  - authoritative `den` validation path remains green

### Slice 3

- Extended the repo-local host inventory with explicit feature selection in
  [inventory.nix](/home/higorprado/nixos/modules/options/inventory.nix)
- Updated `modules/options/shadow-hosts.nix`
  so shadow hosts now import lower-level modules selected from top-level
  feature names
- Dual-published the first real feature owner,
  [llm-agents.nix](/home/higorprado/nixos/modules/features/dev/llm-agents.nix),
  onto the repo-local runtime:
  - `flake.modules.nixos.llm-agents`
  - `flake.modules.homeManager.llm-agents`
- Enabled `llm-agents` for the `predator` shadow host via
  [predator.nix](/home/higorprado/nixos/modules/hosts/predator.nix)
- Validation:
  - `nix eval --apply 'pkgs: builtins.length pkgs' path:$PWD#dendritic.nixosConfigurations.predator.config.home-manager.users.higorprado.home.packages`
  - `nix build --no-link --print-out-paths path:$PWD#dendritic.nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`
  - `nix build --no-link --print-out-paths path:$PWD#dendritic.nixosConfigurations.predator.config.system.build.toplevel`
  - `./scripts/run-validation-gates.sh`
- Outcome:
  - `predator` shadow HM package count is now `13`
  - the `predator` shadow HM and system paths both build with a real feature
    imported through the repo-local runtime
  - authoritative `den` validation path remains green

### Slice 4

- Dual-published the host-aware core owner
  [nix-settings.nix](/home/higorprado/nixos/modules/features/core/nix-settings.nix)
  onto the repo-local runtime as `flake.modules.nixos.nix-settings`
- Started using repo-local default feature selection in
  the former `den-defaults` shim
  through `repo.defaults.hostFeatures = [ "nix-settings" ]`
- Validation:
  - `nix eval --json path:$PWD#dendritic.nixosConfigurations.predator.config.nix.settings.trusted-users`
  - `nix eval --json path:$PWD#dendritic.nixosConfigurations.aurelius.config.nix.settings.trusted-users`
  - `nix eval --json path:$PWD#dendritic.nixosConfigurations.predator.config.programs.nh.enable`
  - `nix eval --json path:$PWD#dendritic.nixosConfigurations.aurelius.config.programs.nh.enable`
  - `nix build --no-link --print-out-paths path:$PWD#dendritic.nixosConfigurations.predator.config.system.build.toplevel`
  - `./scripts/run-validation-gates.sh`
- Outcome:
  - both shadow hosts now resolve `nix.settings.trusted-users = [ "root" "higorprado" ]`
  - both shadow hosts now resolve `programs.nh.enable = true`
  - `predator` shadow system still builds after adding a global host-aware
    default feature
  - authoritative `den` validation path remains green

### Slice 5

- Dual-published the mixed-surface owner
  [fish.nix](/home/higorprado/nixos/modules/features/shell/fish.nix)
  onto the repo-local runtime as:
  - `flake.modules.nixos.fish`
  - `flake.modules.homeManager.fish`
- Added explicit shadow feature selection for `fish` in:
  - [predator.nix](/home/higorprado/nixos/modules/hosts/predator.nix)
  - [aurelius.nix](/home/higorprado/nixos/modules/hosts/aurelius.nix)
- Validation:
  - `nix eval --json path:$PWD#dendritic.nixosConfigurations.predator.config.programs.fish.shellAbbrs`
  - `nix eval --json path:$PWD#dendritic.nixosConfigurations.aurelius.config.programs.fish.shellAbbrs`
  - `nix eval --json path:$PWD#dendritic.nixosConfigurations.predator.config.home-manager.users.higorprado.programs.fish.shellAbbrs`
  - `nix eval --json path:$PWD#dendritic.nixosConfigurations.predator.config.home-manager.users.higorprado.programs.zoxide.enable`
  - `nix build --no-link --print-out-paths path:$PWD#dendritic.nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`
  - `nix build --no-link --print-out-paths path:$PWD#dendritic.nixosConfigurations.predator.config.system.build.toplevel`
  - `./scripts/run-validation-gates.sh`
- Outcome:
  - both shadow hosts now resolve the Fish system abbreviation surface
  - `predator` shadow HM now resolves the Fish and Zoxide user surface through
    the repo-local runtime
  - authoritative `den` validation path remains green

### Slice 6

- Removed the generic shadow host generator in
  `modules/options/shadow-hosts.nix`
  because it had drifted into a framework-style shape that was not aligned with
  the dendritic pattern
- Moved shadow configuration declaration into the host owners themselves:
  - [predator.nix](/home/higorprado/nixos/modules/hosts/predator.nix)
  - [aurelius.nix](/home/higorprado/nixos/modules/hosts/aurelius.nix)
- Dual-published the user owner
  [higorprado.nix](/home/higorprado/nixos/modules/users/higorprado.nix)
  as lower-level modules:
  - `flake.modules.nixos.higorprado`
  - `flake.modules.homeManager.higorprado`
- Removed dead repo-local shadow abstractions that only existed to support the
  deleted generator:
  - `repo.defaults.hostFeatures`
  - shadow inventory `features`
  - shadow inventory `homeManagerUsers`
- Kept `repo-runtime-contracts.nix` as the local lower-level contract surface
  and added the shared `catppuccin` HM module there because multiple migrated
  owners already publish `catppuccin.*` options
- Validation:
  - `nix eval --raw path:$PWD#dendritic.nixosConfigurations.predator.config.networking.hostName`
  - `nix eval --raw path:$PWD#dendritic.nixosConfigurations.predator.config.home-manager.users.higorprado.home.stateVersion`
  - `nix eval --raw path:$PWD#dendritic.nixosConfigurations.aurelius.config.networking.hostName`
  - `nix eval --json path:$PWD#dendritic.nixosConfigurations.predator.config.home-manager.users.higorprado.programs.fish.shellAbbrs`
  - `nix build --no-link --print-out-paths path:$PWD#dendritic.nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`
  - `nix build --no-link --print-out-paths path:$PWD#dendritic.nixosConfigurations.predator.config.system.build.toplevel`
  - `./scripts/run-validation-gates.sh`
- Outcome:
  - the `dendritic` shadow hosts are now declared by their host modules instead
    of being generated from inventory
  - the repo-local runtime shape is materially closer to the dendritic example:
    top-level modules declaring lower-level modules and configurations as values
  - authoritative `den` validation path remains green

### Slice 7

- Dual-published the mixed host/user owner
  [ssh.nix](/home/higorprado/nixos/modules/features/system/ssh.nix)
  onto the repo-local runtime as:
  - `flake.modules.nixos.ssh`
  - `flake.modules.homeManager.ssh`
- Imported the local NixOS SSH module in both shadow hosts:
  - [predator.nix](/home/higorprado/nixos/modules/hosts/predator.nix)
  - [aurelius.nix](/home/higorprado/nixos/modules/hosts/aurelius.nix)
- Imported the local HM SSH module in the `predator` shadow user path, which is
  the only host currently carrying Home Manager in the shadow runtime
- Validation:
  - `nix eval --json path:$PWD#dendritic.nixosConfigurations.predator.config.services.openssh.settings`
  - `nix eval --json path:$PWD#dendritic.nixosConfigurations.aurelius.config.services.openssh.settings`
  - `nix eval --json path:$PWD#dendritic.nixosConfigurations.predator.config.home-manager.users.higorprado.programs.ssh.includes`
  - `nix build --no-link --print-out-paths path:$PWD#dendritic.nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`
  - `nix build --no-link --print-out-paths path:$PWD#dendritic.nixosConfigurations.predator.config.system.build.toplevel`
  - `./scripts/run-validation-gates.sh`
- Outcome:
  - both shadow hosts now resolve the repo-local OpenSSH surface
  - the `predator` shadow HM path now resolves the repo-local user SSH surface
  - authoritative `den` validation path remains green

### Slice 8

- Dual-published the HM-only owner
  [git-gh.nix](/home/higorprado/nixos/modules/features/shell/git-gh.nix)
  onto the repo-local runtime as `flake.modules.homeManager.git-gh`
- Imported the local HM Git/GitHub module into the `predator` shadow user path
  in [predator.nix](/home/higorprado/nixos/modules/hosts/predator.nix)
- Validation:
  - `nix eval --json path:$PWD#dendritic.nixosConfigurations.predator.config.home-manager.users.higorprado.programs.git.enable`
  - `nix eval --json path:$PWD#dendritic.nixosConfigurations.predator.config.home-manager.users.higorprado.programs.gh.enable`
  - `nix build --no-link --print-out-paths path:$PWD#dendritic.nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`
  - `./scripts/run-validation-gates.sh`
- Outcome:
  - the `predator` shadow HM path now resolves the repo-local Git and GitHub
    CLI surface
  - authoritative `den` validation path remains green

### Slice 23

- Dual-published four NixOS-only owners onto the repo-local runtime:
  - [maintenance-smartd.nix](/home/higorprado/nixos/modules/features/system/maintenance-smartd.nix)
    as `flake.modules.nixos.maintenance-smartd`
  - [packages-fonts.nix](/home/higorprado/nixos/modules/features/desktop/packages-fonts.nix)
    as `flake.modules.nixos.packages-fonts`
  - [packages-docs-tools.nix](/home/higorprado/nixos/modules/features/dev/packages-docs-tools.nix)
    as `flake.modules.nixos.packages-docs-tools`
  - [nix-settings-desktop.nix](/home/higorprado/nixos/modules/features/core/nix-settings-desktop.nix)
    as `flake.modules.nixos.nix-settings-desktop`
- Imported those lower-level modules explicitly in the `predator` shadow host in
  [predator.nix](/home/higorprado/nixos/modules/hosts/predator.nix)
- Validation:
  - `nix eval --json path:$PWD#dendritic.nixosConfigurations.predator.config.services.smartd.enable`
  - `nix eval --json path:$PWD#dendritic.nixosConfigurations.predator.config.nix.settings.extra-substituters`
  - `nix eval --apply 'pkgs: builtins.any (pkg: let n = (pkg.name or pkg.pname or ""); in builtins.match ".*(font-awesome|fira-code|meslo|jetbrains-mono).*" n != null) pkgs' path:$PWD#dendritic.nixosConfigurations.predator.config.fonts.packages`
  - `nix eval --apply 'pkgs: builtins.any (pkg: let n = (pkg.name or pkg.pname or ""); in builtins.match ".*(pandoc|tectonic|mermaid-cli|ghostscript).*" n != null) pkgs' path:$PWD#dendritic.nixosConfigurations.predator.config.environment.systemPackages`
  - `nix build --no-link --print-out-paths path:$PWD#dendritic.nixosConfigurations.predator.config.system.build.toplevel`
  - `./scripts/run-validation-gates.sh`
- Outcome:
  - the `predator` shadow system now resolves the repo-local SMART monitoring,
    desktop cache settings, font set and docs-tool package surface
  - the repo-local runtime shape stayed explicit: feature owners publish
    lower-level modules and the host composes them directly

### Slice 24

- Dual-published the host-aware NixOS owner
  [keyrs.nix](/home/higorprado/nixos/modules/features/system/keyrs.nix)
  as `flake.modules.nixos.keyrs`
- Kept the host dependency flow fully dendritic:
  the owner publishes only the `keyrs` behavior surface, while the concrete
  external module import stays explicit in the `predator` host composition
- Imported the local `keyrs` module explicitly in the `predator` shadow host in
  [predator.nix](/home/higorprado/nixos/modules/hosts/predator.nix)
- Validation:
  - `nix eval --json path:$PWD#dendritic.nixosConfigurations.predator.config.hardware.uinput.enable`
  - `nix eval --json path:$PWD#dendritic.nixosConfigurations.predator.config.services.keyrs.enable`
  - `nix build --no-link --print-out-paths path:$PWD#dendritic.nixosConfigurations.predator.config.system.build.toplevel`
  - `./scripts/run-validation-gates.sh`
- Outcome:
  - the `predator` shadow system now resolves the repo-local `keyrs` surface
  - the external `keyrs` module is imported at the host composition boundary,
    avoiding config-dependent `imports` inside the lower-level module

### Slice 25

- Added the real desktop composition contract
  `custom.niri.standaloneSession` to
  [repo-runtime-contracts.nix](/home/higorprado/nixos/modules/options/repo-runtime-contracts.nix)
  instead of leaving the option declaration inside a feature owner
- Dual-published the reusable desktop owners:
  - [niri.nix](/home/higorprado/nixos/modules/features/desktop/niri.nix)
    as:
    - `flake.modules.nixos.niri`
    - `flake.modules.homeManager.niri`
  - [dms.nix](/home/higorprado/nixos/modules/features/desktop/dms.nix)
    as:
    - `flake.modules.nixos.dms`
    - `flake.modules.homeManager.dms`
  - [dms-wallpaper.nix](/home/higorprado/nixos/modules/features/desktop/dms-wallpaper.nix)
    as `flake.modules.homeManager.dms-wallpaper`
- Dual-published the desktop composition owner
  [dms-on-niri.nix](/home/higorprado/nixos/modules/desktops/dms-on-niri.nix)
  as:
  - `flake.modules.nixos.desktop-dms-on-niri`
  - `flake.modules.homeManager.desktop-dms-on-niri`
- Kept external imports explicit at the host boundary in
  [predator.nix](/home/higorprado/nixos/modules/hosts/predator.nix):
  - `host.inputs.niri.nixosModules.niri`
  - `host.inputs.dms.nixosModules.dank-material-shell`
  - `host.inputs.dms.nixosModules.greeter`
- Imported the new repo-local desktop modules explicitly into the `predator`
  shadow system and HM path
- Validation:
  - `nix eval --json path:$PWD#dendritic.nixosConfigurations.predator.config.custom.niri.standaloneSession`
  - `nix eval --json path:$PWD#dendritic.nixosConfigurations.predator.config.programs.niri.enable`
  - `nix eval --json path:$PWD#dendritic.nixosConfigurations.predator.config.home-manager.users.higorprado.programs.dank-material-shell.enable`
  - `nix build --no-link --print-out-paths path:$PWD#dendritic.nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`
  - `nix build --no-link --print-out-paths path:$PWD#dendritic.nixosConfigurations.predator.config.system.build.toplevel`
  - `./scripts/run-validation-gates.sh`
- Outcome:
  - the `predator` shadow now resolves the repo-local `niri`/`dms` desktop stack
  - the `niri` composition contract lives in the repo runtime surface, not in a
    feature file
  - external NixOS modules remain imported concretely by the host, matching the
    dendritic composition boundary

### Slice 26

- Added an explicit Home Manager path to the
  [aurelius.nix](/home/higorprado/nixos/modules/hosts/aurelius.nix) shadow host
  using already-migrated owners:
  - `homeManager.repo-context`
  - `homeManager.higorprado`
  - `homeManager.core-user-packages`
  - `homeManager.fish`
  - `homeManager.git-gh`
  - `homeManager.ssh`
- Kept the host shape dendritic:
  the `aurelius` host declares its own concrete HM composition instead of
  relying on selector/generator logic
- Validation:
  - `nix eval --raw path:$PWD#dendritic.nixosConfigurations.aurelius.config.home-manager.users.higorprado.home.stateVersion`
  - `nix eval --json path:$PWD#dendritic.nixosConfigurations.aurelius.config.home-manager.users.higorprado.programs.git.enable`
  - `nix eval --json path:$PWD#dendritic.nixosConfigurations.aurelius.config.home-manager.users.higorprado.programs.ssh.enable`
  - `nix build --no-link --print-out-paths path:$PWD#dendritic.nixosConfigurations.aurelius.config.home-manager.users.higorprado.home.path`
  - `./scripts/run-validation-gates.sh`
- Outcome:
  - the `aurelius` shadow now exposes a concrete HM user path
  - HM surface evaluation is green for `stateVersion`, Git and SSH
  - direct `home.path` build is still limited locally by the known
    `x86_64-linux` host vs `aarch64-linux` target mismatch, not by a migration
    regression

### Slice 27

- Dual-published the alternate desktop composition
  [niri-standalone.nix](/home/higorprado/nixos/modules/desktops/niri-standalone.nix)
  as:
  - `flake.modules.nixos.desktop-niri-standalone`
  - `flake.modules.homeManager.desktop-niri-standalone`
- Kept the shape parallel to
  [dms-on-niri.nix](/home/higorprado/nixos/modules/desktops/dms-on-niri.nix):
  the composition publishes lower-level modules and carries only composition
  defaults plus user-facing config provisioning
- Validation:
  - `./scripts/run-validation-gates.sh`
- Outcome:
  - the repo-local runtime now has both desktop composition owners published
  - this slice intentionally stops at module publication; no new shadow
    configuration was introduced yet for `desktop-niri-standalone`

### Slice 28

- Dual-published a large part of the former `den.default.includes` baseline as
  repo-local NixOS modules:
  - [system-base.nix](/home/higorprado/nixos/modules/features/core/system-base.nix)
    -> `flake.modules.nixos.system-base`
  - [home-manager-settings.nix](/home/higorprado/nixos/modules/features/core/home-manager-settings.nix)
    -> `flake.modules.nixos.home-manager-settings`
  - [nixpkgs-settings.nix](/home/higorprado/nixos/modules/features/core/nixpkgs-settings.nix)
    -> `flake.modules.nixos.nixpkgs-settings`
  - [networking.nix](/home/higorprado/nixos/modules/features/system/networking.nix)
    -> `flake.modules.nixos.networking`
  - [security.nix](/home/higorprado/nixos/modules/features/system/security.nix)
    -> `flake.modules.nixos.security`
  - [keyboard.nix](/home/higorprado/nixos/modules/features/system/keyboard.nix)
    -> `flake.modules.nixos.keyboard`
  - [maintenance.nix](/home/higorprado/nixos/modules/features/system/maintenance.nix)
    -> `flake.modules.nixos.maintenance`
  - [tailscale.nix](/home/higorprado/nixos/modules/features/system/tailscale.nix)
    -> `flake.modules.nixos.tailscale`
- Imported that baseline explicitly into both shadow hosts:
  - [predator.nix](/home/higorprado/nixos/modules/hosts/predator.nix)
  - [aurelius.nix](/home/higorprado/nixos/modules/hosts/aurelius.nix)
- Removed host-local duplication that is now owned by those defaults:
  - `system.stateVersion`
  - `home-manager.useGlobalPkgs`
  - `home-manager.useUserPackages`
  - `home-manager.backupFileExtension`
- Validation:
  - `nix eval --raw path:$PWD#dendritic.nixosConfigurations.predator.config.system.stateVersion`
  - `nix eval --json path:$PWD#dendritic.nixosConfigurations.predator.config.services.tailscale.enable`
  - `nix eval --json path:$PWD#dendritic.nixosConfigurations.aurelius.config.networking.networkmanager.enable`
  - `nix build --no-link --print-out-paths path:$PWD#dendritic.nixosConfigurations.predator.config.system.build.toplevel`
  - `./scripts/run-validation-gates.sh`
- Outcome:
  - a substantial shared baseline now flows through repo-local lower-level
    modules instead of only through `den.default.includes`
  - host shadow configs became slightly simpler while staying explicitly
    composed in the host files

### Slice 29

- Changed [modules/den.nix](/home/higorprado/nixos/modules/den.nix) to import
  the `den` schema/context/lib modules explicitly instead of importing
  `inputs.den.flakeModule` wholesale
- Intentionally omitted `den/modules/config.nix`, which is the piece that
  materializes `config.flake` outputs from `den.hosts` / `den.homes`
- Promoted the repo-local runtime in
  [configurations-nixos.nix](/home/higorprado/nixos/modules/options/configurations-nixos.nix)
  from `flake.dendritic.nixosConfigurations` to canonical
  `flake.nixosConfigurations`
- Kept a compatibility alias under `flake.dendritic` so the existing migration
  log and spot checks still have the old shadow path available
- Validation:
  - `nix eval --raw path:$PWD#nixosConfigurations.predator.config.system.stateVersion`
  - `nix eval --raw path:$PWD#nixosConfigurations.aurelius.config.system.stateVersion`
  - `nix eval --raw path:$PWD#dendritic.nixosConfigurations.predator.config.system.stateVersion`
  - `nix build --no-link --print-out-paths path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`
  - `./scripts/run-validation-gates.sh`
- Outcome:
  - canonical `#nixosConfigurations.*` now come from the repo-local dendritic
    runtime rather than from `den`
  - `den` remains temporarily as schema/context support while its output
    materialization has been removed from the active path

### Slice 9

- Added the HM-only shared owners:
  - [core-user-packages.nix](/home/higorprado/nixos/modules/features/shell/core-user-packages.nix)
  - [starship.nix](/home/higorprado/nixos/modules/features/shell/starship.nix)
- Published them onto the repo-local runtime as:
  - `flake.modules.homeManager.core-user-packages`
  - `flake.modules.homeManager.starship`
- Imported both into the `predator` shadow HM path in
  [predator.nix](/home/higorprado/nixos/modules/hosts/predator.nix)
- Validation:
  - `nix eval --json path:$PWD#dendritic.nixosConfigurations.predator.config.home-manager.users.higorprado.programs.fzf.enable`
  - `nix eval --json path:$PWD#dendritic.nixosConfigurations.predator.config.home-manager.users.higorprado.programs.starship.enable`
  - `nix build --no-link --print-out-paths path:$PWD#dendritic.nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`
  - `./scripts/run-validation-gates.sh`
- Outcome:
  - the `predator` shadow HM path now resolves shared user packages and the
    prompt surface through the repo-local runtime
  - authoritative `den` validation path remains green

### Slice 10

- Added two more HM-only shared owners:
  - [terminal-tmux.nix](/home/higorprado/nixos/modules/features/shell/terminal-tmux.nix)
  - [tui-tools.nix](/home/higorprado/nixos/modules/features/shell/tui-tools.nix)
- Published them onto the repo-local runtime as:
  - `flake.modules.homeManager.terminal-tmux`
  - `flake.modules.homeManager.tui-tools`
- Imported both into the `predator` shadow HM path in
  [predator.nix](/home/higorprado/nixos/modules/hosts/predator.nix)
- Validation:
  - `nix eval --json path:$PWD#dendritic.nixosConfigurations.predator.config.home-manager.users.higorprado.programs.tmux.enable`
  - `nix eval --json path:$PWD#dendritic.nixosConfigurations.predator.config.home-manager.users.higorprado.programs.yazi.enable`
  - `nix eval --json path:$PWD#dendritic.nixosConfigurations.predator.config.home-manager.users.higorprado.programs.zellij.enable`
  - `nix build --no-link --print-out-paths path:$PWD#dendritic.nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`
  - `./scripts/run-validation-gates.sh`
- Outcome:
  - the `predator` shadow HM path now resolves tmux and the core TUI tool
    surface through the repo-local runtime
  - authoritative `den` validation path remains green

### Slice 11

- Added two more HM-only shared owners:
  - [dev-tools.nix](/home/higorprado/nixos/modules/features/dev/dev-tools.nix)
  - [monitoring-tools.nix](/home/higorprado/nixos/modules/features/shell/monitoring-tools.nix)
- Published them onto the repo-local runtime as:
  - `flake.modules.homeManager.dev-tools`
  - `flake.modules.homeManager.monitoring-tools`
- Imported both into the `predator` shadow HM path in
  [predator.nix](/home/higorprado/nixos/modules/hosts/predator.nix)
- Validation:
  - `nix eval --json path:$PWD#dendritic.nixosConfigurations.predator.config.home-manager.users.higorprado.programs.bat.enable`
  - `nix eval --json path:$PWD#dendritic.nixosConfigurations.predator.config.home-manager.users.higorprado.programs.eza.enable`
  - `nix eval --json path:$PWD#dendritic.nixosConfigurations.predator.config.home-manager.users.higorprado.xdg.configFile.\"htop/htoprc\".source`
  - `nix build --no-link --print-out-paths path:$PWD#dendritic.nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`
  - `./scripts/run-validation-gates.sh`
- Outcome:
  - the `predator` shadow HM path now resolves shared dev utilities and the
    tracked `htop` config through the repo-local runtime
  - authoritative `den` validation path remains green

### Slice 12

- Added the HM-only terminal surface owner
  [terminals.nix](/home/higorprado/nixos/modules/features/shell/terminals.nix)
  as `flake.modules.homeManager.terminals`
- Imported it into the `predator` shadow HM path in
  [predator.nix](/home/higorprado/nixos/modules/hosts/predator.nix)
- Validation:
  - `nix eval --json path:$PWD#dendritic.nixosConfigurations.predator.config.home-manager.users.higorprado.programs.kitty.enable`
  - `nix eval --json path:$PWD#dendritic.nixosConfigurations.predator.config.home-manager.users.higorprado.programs.wezterm.enable`
  - `nix eval --raw \"path:$PWD#dendritic.nixosConfigurations.predator.config.home-manager.users.higorprado.home.sessionVariables.TERMINAL\"`
  - `nix build --no-link --print-out-paths path:$PWD#dendritic.nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`
  - `./scripts/run-validation-gates.sh`
- Outcome:
  - the `predator` shadow HM path now resolves the tracked terminal stack
    through the repo-local runtime
  - authoritative `den` validation path remains green

### Slice 13

- Added three desktop HM-only owners:
  - [media-tools.nix](/home/higorprado/nixos/modules/features/desktop/media-tools.nix)
  - [media-cava.nix](/home/higorprado/nixos/modules/features/desktop/media-cava.nix)
  - [desktop-viewers.nix](/home/higorprado/nixos/modules/features/desktop/desktop-viewers.nix)
- Published them onto the repo-local runtime as:
  - `flake.modules.homeManager.media-tools`
  - `flake.modules.homeManager.media-cava`
  - `flake.modules.homeManager.desktop-viewers`
- Imported them into the `predator` shadow HM path in
  [predator.nix](/home/higorprado/nixos/modules/hosts/predator.nix)
- Validation:
  - `nix eval --json path:$PWD#dendritic.nixosConfigurations.predator.config.home-manager.users.higorprado.programs.cava.enable`
  - `nix eval --raw \"path:$PWD#dendritic.nixosConfigurations.predator.config.home-manager.users.higorprado.xdg.mimeApps.defaultApplications.\\\"application/pdf\\\"\"`
  - `nix eval --apply 'pkgs: builtins.any (pkg: (pkg.pname or \"\") == \"vlc\") pkgs' path:$PWD#dendritic.nixosConfigurations.predator.config.home-manager.users.higorprado.home.packages`
  - `nix build --no-link --print-out-paths path:$PWD#dendritic.nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`
  - `./scripts/run-validation-gates.sh`
- Outcome:
  - the `predator` shadow HM path now resolves tracked media packages, the Cava
    configuration, and the viewer MIME routing through the repo-local runtime
  - authoritative `den` validation path remains green

### Slice 14

- Added two more desktop HM-only shared owners:
  - [desktop-base.nix](/home/higorprado/nixos/modules/features/desktop/desktop-base.nix)
  - [theme-base.nix](/home/higorprado/nixos/modules/features/desktop/theme-base.nix)
- Published them onto the repo-local runtime as:
  - `flake.modules.homeManager.desktop-base`
  - `flake.modules.homeManager.theme-base`
- Imported them into the `predator` shadow HM path in
  [predator.nix](/home/higorprado/nixos/modules/hosts/predator.nix)
- Validation:
  - `nix eval --json path:$PWD#dendritic.nixosConfigurations.predator.config.home-manager.users.higorprado.xdg.enable`
  - `nix eval --json path:$PWD#dendritic.nixosConfigurations.predator.config.home-manager.users.higorprado.gtk.enable`
  - `nix eval --json path:$PWD#dendritic.nixosConfigurations.predator.config.home-manager.users.higorprado.catppuccin.flavor`
  - `nix build --no-link --print-out-paths path:$PWD#dendritic.nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`
  - `./scripts/run-validation-gates.sh`
- Outcome:
  - the `predator` shadow HM path now resolves the base desktop XDG surface and
    the shared theme surface through the repo-local runtime
  - authoritative `den` validation path remains green

### Slice 15

- Added two host-context-dependent desktop HM owners:
  - [desktop-apps.nix](/home/higorprado/nixos/modules/features/desktop/desktop-apps.nix)
  - [theme-zen.nix](/home/higorprado/nixos/modules/features/desktop/theme-zen.nix)
- Published them onto the repo-local runtime as:
  - `flake.modules.homeManager.desktop-apps`
  - `flake.modules.homeManager.theme-zen`
- Both read host-specific data through `config.repo.context.host`, preserving
  the dendritic rule that cross-file sharing happens through config, not through
  `specialArgs`
- Imported them into the `predator` shadow HM path in
  [predator.nix](/home/higorprado/nixos/modules/hosts/predator.nix)
- Validation:
  - `nix eval --json path:$PWD#dendritic.nixosConfigurations.predator.config.home-manager.users.higorprado.programs.firefox.enable`
  - `nix eval --json path:$PWD#dendritic.nixosConfigurations.predator.config.home-manager.users.higorprado.programs.brave.enable`
  - `nix eval --json path:$PWD#dendritic.nixosConfigurations.predator.config.home-manager.users.higorprado.home.activation.syncZenCatppuccinTheme.data`
  - `nix build --no-link --print-out-paths path:$PWD#dendritic.nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`
  - `./scripts/run-validation-gates.sh`
- Outcome:
  - the `predator` shadow HM path now resolves browser/apps wiring and the Zen
    theme sync activation through the repo-local runtime
  - authoritative `den` validation path remains green

### Slice 16

- Added three more desktop shared owners:
  - [nautilus.nix](/home/higorprado/nixos/modules/features/desktop/nautilus.nix)
  - [fcitx5.nix](/home/higorprado/nixos/modules/features/desktop/fcitx5.nix)
  - [wayland-tools.nix](/home/higorprado/nixos/modules/features/desktop/wayland-tools.nix)
- Published them onto the repo-local runtime as:
  - `flake.modules.nixos.nautilus`
  - `flake.modules.homeManager.nautilus`
  - `flake.modules.nixos.fcitx5`
  - `flake.modules.homeManager.fcitx5`
  - `flake.modules.homeManager.wayland-tools`
- Kept the shape explicit:
  - NixOS surfaces stay on the feature owner as lower-level modules
  - HM surfaces stay on the feature owner as lower-level modules
  - the `predator` host imports those modules directly instead of routing them
    through inventory selectors or helper factories
- Imported them into the `predator` shadow path in
  [predator.nix](/home/higorprado/nixos/modules/hosts/predator.nix)
- Validation:
  - `nix eval --json path:$PWD#dendritic.nixosConfigurations.predator.config.services.gvfs.enable`
  - `nix eval --json path:$PWD#dendritic.nixosConfigurations.predator.config.i18n.inputMethod.type`
  - `nix eval --json path:$PWD#dendritic.nixosConfigurations.predator.config.i18n.inputMethod.fcitx5.addons`
  - `nix eval --json path:$PWD#dendritic.nixosConfigurations.predator.config.home-manager.users.higorprado.i18n.inputMethod.type`
  - `nix eval --json path:$PWD#dendritic.nixosConfigurations.predator.config.home-manager.users.higorprado.xdg.mimeApps.defaultApplications`
  - `nix eval --apply 'pkgs: builtins.any (pkg: let n = (pkg.name or pkg.pname or ""); in builtins.match ".*(nautilus|waybar|wlr-randr).*" n != null) pkgs' path:$PWD#dendritic.nixosConfigurations.predator.config.home-manager.users.higorprado.home.packages`
  - `nix build --no-link --print-out-paths path:$PWD#dendritic.nixosConfigurations.predator.config.system.build.toplevel`
  - `nix build --no-link --print-out-paths path:$PWD#dendritic.nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`
  - `./scripts/run-validation-gates.sh`
- Outcome:
  - the `predator` shadow system path now resolves the desktop file-manager and
    input-method system surface through the repo-local runtime
  - the `predator` shadow HM path now resolves Nautilus MIME routing, Wayland
    utilities, and the user-side `fcitx5` surface through the repo-local
    runtime
  - authoritative `den` validation path remains green

### Slice 17

- Added two more desktop shared owners:
  - [gaming.nix](/home/higorprado/nixos/modules/features/desktop/gaming.nix)
  - [music-client.nix](/home/higorprado/nixos/modules/features/desktop/music-client.nix)
- Published them onto the repo-local runtime as:
  - `flake.modules.nixos.gaming`
  - `flake.modules.homeManager.gaming`
  - `flake.modules.homeManager.music-client`
- Kept the host-aware owner (`music-client`) on the dendritic path:
  - host-specific packages are read through `config.repo.context.host`
  - no `specialArgs`, helper factory, or extra option contract was introduced
- Imported them into the `predator` shadow path in
  [predator.nix](/home/higorprado/nixos/modules/hosts/predator.nix)
- Validation:
  - `nix eval --json path:$PWD#dendritic.nixosConfigurations.predator.config.programs.steam.enable`
  - `nix eval --json path:$PWD#dendritic.nixosConfigurations.predator.config.programs.gamescope.enable`
  - `nix eval --json path:$PWD#dendritic.nixosConfigurations.predator.config.home-manager.users.higorprado.services.mpd.enable`
  - `nix eval --apply 'pkgs: builtins.any (pkg: let n = (pkg.name or pkg.pname or ""); in builtins.match ".*(heroic|lutris|protonplus|steam-run|rmpc|spotatui).*" n != null) pkgs' path:$PWD#dendritic.nixosConfigurations.predator.config.home-manager.users.higorprado.home.packages`
  - `nix build --no-link --print-out-paths path:$PWD#dendritic.nixosConfigurations.predator.config.system.build.toplevel`
  - `nix build --no-link --print-out-paths path:$PWD#dendritic.nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`
  - `./scripts/run-validation-gates.sh`
- Outcome:
  - the `predator` shadow system path now resolves the gaming system surface
    through the repo-local runtime
  - the `predator` shadow HM path now resolves the gaming packages and the MPD
    / `rmpc` music-client surface through the repo-local runtime
  - authoritative `den` validation path remains green

### Slice 18

- Added three more HM-only dev/editor owners:
  - [editor-vscode.nix](/home/higorprado/nixos/modules/features/dev/editor-vscode.nix)
  - [editor-zed.nix](/home/higorprado/nixos/modules/features/dev/editor-zed.nix)
  - [dev-devenv.nix](/home/higorprado/nixos/modules/features/dev/dev-devenv.nix)
- Published them onto the repo-local runtime as:
  - `flake.modules.homeManager.editor-vscode`
  - `flake.modules.homeManager.editor-zed`
  - `flake.modules.homeManager.dev-devenv`
- Imported them into the `predator` shadow HM path in
  [predator.nix](/home/higorprado/nixos/modules/hosts/predator.nix)
- Validation:
  - `nix eval --json path:$PWD#dendritic.nixosConfigurations.predator.config.home-manager.users.higorprado.programs.vscode.enable`
  - `nix eval --json path:$PWD#dendritic.nixosConfigurations.predator.config.home-manager.users.higorprado.programs.direnv.enable`
  - `nix eval --apply 'pkgs: builtins.any (pkg: let n = (pkg.name or pkg.pname or ""); in builtins.match ".*(zed|devenv|cachix).*" n != null) pkgs' path:$PWD#dendritic.nixosConfigurations.predator.config.home-manager.users.higorprado.home.packages`
  - `nix build --no-link --print-out-paths path:$PWD#dendritic.nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`
  - `./scripts/run-validation-gates.sh`
- Outcome:
  - the `predator` shadow HM path now resolves the VS Code surface and the
    `devenv` / `direnv` developer workflow through the repo-local runtime
  - the `predator` shadow HM path also resolves the additional Zed package
    surface through the repo-local runtime
  - authoritative `den` validation path remains green

### Slice 19

- Added three more user-surface owners:
  - [backup-service.nix](/home/higorprado/nixos/modules/features/system/backup-service.nix)
  - [editor-neovim.nix](/home/higorprado/nixos/modules/features/dev/editor-neovim.nix)
  - [editor-emacs.nix](/home/higorprado/nixos/modules/features/dev/editor-emacs.nix)
- Published them onto the repo-local runtime as:
  - `flake.modules.homeManager.backup-service`
  - `flake.modules.nixos.editor-neovim`
  - `flake.modules.homeManager.editor-neovim`
  - `flake.modules.homeManager.editor-emacs`
- Imported them into the `predator` shadow path in
  [predator.nix](/home/higorprado/nixos/modules/hosts/predator.nix)
- Validation:
  - `nix eval --json path:$PWD#dendritic.nixosConfigurations.predator.config.security.pam.services.systemd-user.limits`
  - `nix eval --json path:$PWD#dendritic.nixosConfigurations.predator.config.home-manager.users.higorprado.programs.neovim.enable`
  - `nix eval --json path:$PWD#dendritic.nixosConfigurations.predator.config.home-manager.users.higorprado.services.emacs.enable`
  - `nix eval --json path:$PWD#dendritic.nixosConfigurations.predator.config.home-manager.users.higorprado.systemd.user.timers.critical-backup.Timer.OnCalendar`
  - `nix build --no-link --print-out-paths path:$PWD#dendritic.nixosConfigurations.predator.config.system.build.toplevel`
  - `nix build --no-link --print-out-paths path:$PWD#dendritic.nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`
  - `./scripts/run-validation-gates.sh`
- Outcome:
  - the `predator` shadow system path now resolves the Neovim PAM/session
    limits through the repo-local runtime
  - the `predator` shadow HM path now resolves the backup timer, Neovim user
    surface, and Emacs service surface through the repo-local runtime
  - authoritative `den` validation path remains green

### Slice 20

- Added three more system/shared owners:
  - [docker.nix](/home/higorprado/nixos/modules/features/system/docker.nix)
  - [packages-toolchains.nix](/home/higorprado/nixos/modules/features/dev/packages-toolchains.nix)
  - [packages-system-tools.nix](/home/higorprado/nixos/modules/features/system/packages-system-tools.nix)
- Published them onto the repo-local runtime as:
  - `flake.modules.nixos.docker`
  - `flake.modules.homeManager.docker`
  - `flake.modules.nixos.packages-toolchains`
  - `flake.modules.homeManager.packages-toolchains`
  - `flake.modules.nixos.packages-system-tools`
- Imported them explicitly in:
  - [predator.nix](/home/higorprado/nixos/modules/hosts/predator.nix)
  - [aurelius.nix](/home/higorprado/nixos/modules/hosts/aurelius.nix)
- Validation:
  - `nix eval --json path:$PWD#dendritic.nixosConfigurations.predator.config.virtualisation.docker.enable`
  - `nix eval --json path:$PWD#dendritic.nixosConfigurations.predator.config.home-manager.users.higorprado.programs.fish.shellAbbrs`
  - `nix eval --raw path:$PWD#dendritic.nixosConfigurations.predator.config.home-manager.users.higorprado.programs.fish.interactiveShellInit`
  - `nix eval --apply 'pkgs: builtins.any (pkg: let n = (pkg.name or pkg.pname or ""); in builtins.match ".*(gcc|nodejs|btrfs-progs).*" n != null) pkgs' path:$PWD#dendritic.nixosConfigurations.predator.config.environment.systemPackages`
  - `nix eval --apply 'pkgs: builtins.any (pkg: let n = (pkg.name or pkg.pname or ""); in builtins.match ".*(btrfs-progs).*" n != null) pkgs' path:$PWD#dendritic.nixosConfigurations.aurelius.config.environment.systemPackages`
  - `nix build --no-link --print-out-paths path:$PWD#dendritic.nixosConfigurations.predator.config.system.build.toplevel`
  - `nix build --no-link --print-out-paths path:$PWD#dendritic.nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`
  - `./scripts/run-validation-gates.sh`
- Notes:
  - attempted `nix build --no-link --print-out-paths path:$PWD#dendritic.nixosConfigurations.aurelius.config.system.build.toplevel`
    still does not complete on this machine because the current host is
    `x86_64-linux` and `aurelius` targets `aarch64-linux`; this is a local
    builder/platform limitation, not a regression introduced by this slice
- Outcome:
  - the `predator` shadow system path now resolves Docker, toolchain packages,
    and system filesystem tooling through the repo-local runtime
  - the `predator` shadow HM path now resolves Docker shell abbreviations and
    the toolchain Fish path bootstrap through the repo-local runtime
  - the `aurelius` shadow configuration now evaluates with
    `packages-system-tools` in its system package set
  - authoritative `den` validation path remains green

### Slice 21

- Added four more NixOS-only owners:
  - [packages-server-tools.nix](/home/higorprado/nixos/modules/features/system/packages-server-tools.nix)
  - [podman.nix](/home/higorprado/nixos/modules/features/system/podman.nix)
  - [upower.nix](/home/higorprado/nixos/modules/features/system/upower.nix)
  - [bluetooth.nix](/home/higorprado/nixos/modules/features/system/bluetooth.nix)
- Published them onto the repo-local runtime as:
  - `flake.modules.nixos.packages-server-tools`
  - `flake.modules.nixos.podman`
  - `flake.modules.nixos.upower`
  - `flake.modules.nixos.bluetooth`
- Imported them explicitly in:
  - [predator.nix](/home/higorprado/nixos/modules/hosts/predator.nix)
  - [aurelius.nix](/home/higorprado/nixos/modules/hosts/aurelius.nix)
- Validation:
  - `nix eval --json path:$PWD#dendritic.nixosConfigurations.predator.config.hardware.bluetooth.enable`
  - `nix eval --json path:$PWD#dendritic.nixosConfigurations.predator.config.virtualisation.podman.enable`
  - `nix eval --json path:$PWD#dendritic.nixosConfigurations.predator.config.services.upower.enable`
  - `nix eval --apply 'pkgs: builtins.any (pkg: let n = (pkg.name or pkg.pname or ""); in builtins.match ".*(eza|ripgrep|distrobox).*" n != null) pkgs' path:$PWD#dendritic.nixosConfigurations.aurelius.config.environment.systemPackages`
  - `nix build --no-link --print-out-paths path:$PWD#dendritic.nixosConfigurations.predator.config.system.build.toplevel`
  - `./scripts/run-validation-gates.sh`
- Outcome:
  - the `predator` shadow system path now resolves Bluetooth, Podman, and
    UPower through the repo-local runtime
  - the `aurelius` shadow configuration now evaluates with the server-oriented
    package surface through the repo-local runtime
  - authoritative `den` validation path remains green

### Slice 22

- Added five more NixOS-only owners:
  - [networking-resolved.nix](/home/higorprado/nixos/modules/features/system/networking-resolved.nix)
  - [networking-avahi.nix](/home/higorprado/nixos/modules/features/system/networking-avahi.nix)
  - [audio.nix](/home/higorprado/nixos/modules/features/system/audio.nix)
  - [gnome-keyring.nix](/home/higorprado/nixos/modules/features/desktop/gnome-keyring.nix)
  - [xwayland.nix](/home/higorprado/nixos/modules/features/desktop/xwayland.nix)
- Published them onto the repo-local runtime as:
  - `flake.modules.nixos.networking-resolved`
  - `flake.modules.nixos.networking-avahi`
  - `flake.modules.nixos.audio`
  - `flake.modules.nixos.gnome-keyring`
  - `flake.modules.nixos.xwayland`
- Imported them explicitly in
  [predator.nix](/home/higorprado/nixos/modules/hosts/predator.nix)
- Validation:
  - `nix eval --json path:$PWD#dendritic.nixosConfigurations.predator.config.services.resolved.enable`
  - `nix eval --json path:$PWD#dendritic.nixosConfigurations.predator.config.services.avahi.enable`
  - `nix eval --json path:$PWD#dendritic.nixosConfigurations.predator.config.services.pipewire.enable`
  - `nix eval --json path:$PWD#dendritic.nixosConfigurations.predator.config.services.gnome.gnome-keyring.enable`
  - `nix eval --json path:$PWD#dendritic.nixosConfigurations.predator.config.programs.xwayland.enable`
  - `nix build --no-link --print-out-paths path:$PWD#dendritic.nixosConfigurations.predator.config.system.build.toplevel`
  - `./scripts/run-validation-gates.sh`
- Outcome:
  - the `predator` shadow system path now resolves the resolver, mDNS, audio,
    GNOME keyring, and Xwayland surfaces through the repo-local runtime
  - authoritative `den` validation path remains green

## Final State

- Not complete yet
- Phase 0 baseline is captured for the current authoritative outputs
- Phase 1 has a validated shadow namespace that now builds `predator`
- Phase 2 has started: the shadow path now consumes repo-owned inventory and
  runtime contracts through host-declared configurations instead of a generic
  generator
- Phase 3 has started in small form: one real feature (`llm-agents`) now flows
  through the repo-local runtime
- Another host-aware owner (`nix-settings`) now flows through the repo-local
  runtime via explicit host imports
- Another mixed NixOS/HM owner (`fish`) now flows through the repo-local runtime
  via explicit host imports
- Another mixed NixOS/HM owner (`ssh`) now flows through the repo-local runtime
  via explicit host imports
- Another HM-only owner (`git-gh`) now flows through the repo-local runtime via
  explicit host imports
- Additional HM-only owners (`core-user-packages`, `starship`) now flow through
  the repo-local runtime via explicit host imports
- Additional HM-only owners (`terminal-tmux`, `tui-tools`) now flow through the
  repo-local runtime via explicit host imports
- Additional HM-only owners (`dev-tools`, `monitoring-tools`) now flow through
  the repo-local runtime via explicit host imports
- Another HM-only owner (`terminals`) now flows through the repo-local runtime
  via explicit host imports
- Additional desktop HM-only owners (`media-tools`, `media-cava`,
  `desktop-viewers`) now flow through the repo-local runtime via explicit host
  imports
- Additional desktop HM-only owners (`desktop-base`, `theme-base`) now flow
  through the repo-local runtime via explicit host imports
- Additional host-context-dependent desktop HM owners (`desktop-apps`,
  `theme-zen`) now flow through the repo-local runtime via explicit host imports
- Additional desktop shared owners (`nautilus`, `fcitx5`, `wayland-tools`) are
  being migrated through explicit host imports
- Additional desktop shared owners (`gaming`, `music-client`) are being
  migrated through explicit host imports
- Additional HM-only dev/editor owners (`editor-vscode`, `editor-zed`,
  `dev-devenv`) are being migrated through explicit host imports
- Additional user-surface owners (`backup-service`, `editor-neovim`,
  `editor-emacs`) are being migrated through explicit host imports
- Additional system/shared owners (`docker`, `packages-toolchains`,
  `packages-system-tools`) are being migrated through explicit host imports
- Additional NixOS-only owners (`packages-server-tools`, `podman`, `upower`,
  `bluetooth`) are being migrated through explicit host imports
- Additional NixOS-only owners (`networking-resolved`, `networking-avahi`,
  `audio`, `gnome-keyring`, `xwayland`) are being migrated through explicit
  host imports
- The shadow path now has a user owner published as lower-level NixOS and
  Home Manager modules instead of synthesizing users inside a host generator
- Canonical `flake.nixosConfigurations.*` now comes from the repo-local
  dendritic runtime rather than the `den` output materializer
- Dead `den.hosts.*` and `den.aspects.{predator,aurelius,higorprado}` runtime
  declarations were removed from the active host/user files after the canonical
  cutover, leaving those files focused on top-level inventory and
  `configurations.nixos.*.module`
- Dead `den` composition mirrors were removed from
  [dms-on-niri.nix](/home/higorprado/nixos/modules/desktops/dms-on-niri.nix)
  and
  [niri-standalone.nix](/home/higorprado/nixos/modules/desktops/niri-standalone.nix),
  leaving those files as pure lower-level module publishers for the local
  dendritic runtime
- The extension contract and host skeleton generator were migrated from
  `den.hosts.*.users` to `repo.hosts.<host>.trackedUsers`, and the generated
  host templates now emit concrete dendritic host modules instead of den host
  aspects
- Living operating docs were updated so the active onboarding story matches the
  canonical repo-local dendritic runtime rather than the old den host runtime
- Removed the dead `modules/features/desktop/theme.nix` shim after confirming
  no active code path still consumed `den.aspects.theme`
- Updated human-facing structure and feature/composition workflows to describe
  published `flake.modules.*` plus explicit host imports instead of `den`
  aspect `includes`
- Removed dead den-era contract shims (`den-defaults`, `user-context`, and
  `host-contracts`) after confirming the canonical runtime now owns those
  concerns in
  [repo-runtime-contracts.nix](/home/higorprado/nixos/modules/options/repo-runtime-contracts.nix)
- Removed the former `den-host-context` schema shim after confirming no active
  host path still materializes `den.hosts` with an extended host schema
- Next step: keep shrinking the remaining `den` support surface now that hosts
  and the tracked user no longer dual-declare runtime composition
