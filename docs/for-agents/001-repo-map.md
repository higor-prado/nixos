# Repository Map

Authoritative map of where things live in this dendritic-first repository.

## Top-level layout

```
modules/features/   feature modules grouped under category folders
modules/desktops/   concrete desktop compositions
modules/hosts/      one file per host owner + concrete configuration
modules/nixos.nix   structural NixOS configuration output surface
modules/flake-parts.nix enables `flake.modules.*`
modules/users/      tracked user owner modules; `higorprado.nix` also owns `username`
modules/systems.nix supported flake systems
modules/templates.nix flake template outputs
private/            private overrides (gitignored)
hardware/<name>/    machine-specific: hardware, disko, boot, persistence/reset
lib/                generic helper functions (_helpers.nix, mutable-copy.nix)
pkgs/               custom packages
config/             app/desktop config files and helper payloads (hyprland-standalone, nvim, tmux, waybar, mako, htop, logid, mpd, rmpc, zen, waypaper, devenv templates)
scripts/            validation gate scripts
tests/              fixtures and test runners
docs/for-agents/archive/ archived plans, log tracks, and reports
```

## top-level runtime surfaces

- `modules/nixos.nix` — materializes `flake.nixosConfigurations` from `configurations.nixos.*.module`
- `modules/flake-parts.nix` — enables the `flake-parts` published-module surface
- `modules/users/higorprado.nix` — tracked user publishers plus the canonical `username` fact

## Package ownership map

- **NixOS modules** own machine/runtime concerns: services, boot/session plumbing, drivers, fonts, firewall/network support, `/etc` payloads, system users/groups, and packages required independently of any user home.
- **Home Manager modules** own user environment concerns: CLI tools, editors, GUI apps, prompts, terminals, themes, user services, and packages primarily used interactively by the tracked user.
- **Split a feature across both** when one capability needs both machine plumbing and user configuration.
- **`hardware/<name>/` is not a package-policy bucket**. Keep package policy in feature owners or, if truly host-only, the concrete host owner.

## modules/features/ — category layout

**Core**
- `core/system-base.nix` — base NixOS system config
- `core/nixpkgs-settings.nix` — `nixpkgs.config.allowUnfree` and future nixpkgs settings
- `core/nix-settings.nix` — universal nix daemon settings (max-jobs, store optimization, nh, daemon scheduling)
- `core/nix-cache-settings.nix` — centralized external binary caches for hosts that benefit from desktop/dev upstream caches (numtide, devenv, nixpkgs-python, catppuccin, zed-industries, hyprland)
- `core/home-manager-settings.nix` — HM framework settings

**Shell / Terminal**
- `shell/fish.nix` — fish shell + zoxide + abbreviations
- `shell/starship.nix` — starship prompt
- `shell/terminal-tmux.nix` — tmux with tmux-cpu plugin
- `shell/terminals.nix` — foot, ghostty, kitty, alacritty, wezterm; sets TERMINAL=kitty
- `shell/git-gh.nix` — git + gh CLI config
- `shell/core-user-packages.nix` — essential CLI tools (fzf, btop, vim, curl, ripgrep, etc.)
- `shell/tui-tools.nix` — bundled TUI ergonomics (lazygit, lazydocker, yazi, zellij)
- `shell/monitoring-tools.nix` — htop, btop, bottom, fastfetch

**Desktop**
- `desktop/regreet.nix` — ReGreet greetd greeter with Catppuccin theming (Hyprland)
- `desktop/desktop-base.nix`, `desktop/desktop-apps.nix`, `desktop/desktop-viewers.nix`, `desktop/gnome-keyring.nix`
- `desktop/theme-base.nix`, `desktop/theme-zen.nix` — internal theme ownership split
- `desktop/packages-fonts.nix` — Nerd fonts
- `desktop/media-cava.nix`, `desktop/media-tools.nix`, `desktop/music-client.nix`, `desktop/nautilus.nix`
- `desktop/wayland-tools.nix`, `desktop/fcitx5.nix`
- `desktop/session-applets.nix` — Hyprland user session agents/applets (hyprpolkitagent, nm-applet, blueman-applet, udiskie)
- `desktop/qt-theme.nix` — Qt theming stack (qt5ct/qt6ct + kvantum + Catppuccin)
- `desktop/hyprland.nix` — Hyprland Wayland compositor without automatic idle lock/DPMS
- `desktop/waybar.nix` — Waybar status bar with copy-once config and catppuccin theming
- `desktop/rofi.nix` — Rofi retained for the legacy powermenu while Walker owns launcher and clipboard flows
- `desktop/walker.nix` — Walker launcher and clipboard stack with Elephant backend service, Catppuccin theme sync, and copy-once config
- `desktop/mako.nix` — Mako notification daemon with catppuccin theming
- `desktop/gaming.nix` — Steam gaming with Proton, Gamemode, and NVIDIA NGX/DLSS support
- `desktop/waypaper.nix` — Waypaper GUI wallpaper manager with awww backend and copy-once config

**Dev / Editors / LLM**
- `dev/llm-agents.nix` — operator LLM agent CLIs (Claude Code, Codex, Crush, Kilocode, Opencode)
- `dev/editor-neovim.nix` — Neovim + LSP packages + nvim config sync; nixos block sets PAM fd/process limits for LSP socket creation
- `dev/editor-vscode.nix` — VS Code with extensions
- `dev/editor-emacs.nix` — Emacs (pgtk) + Doom env + socket daemon
- `dev/editor-zed.nix` — Zed editor
- `dev/dev-tools.nix`, `dev/dev-devenv.nix`
- `dev/packages-toolchains.nix`, `dev/packages-docs-tools.nix`


**Media**
- `media/aiostreams.nix` — AIOStreams Stremio addon aggregator (Docker container)
**System**
- `system/networking*.nix`, `system/security.nix`, `system/ssh.nix`
- `system/audio.nix`, `system/bluetooth.nix`, `system/tailscale.nix`
- `system/aurelius-attic-server.nix`, `system/aurelius-attic-local-publisher.nix`, `system/aurelius-github-runner.nix`
- `system/networking-wireguard-client.nix`, `system/networking-wireguard-server.nix`
- `system/docker.nix`, `system/podman.nix`, `system/keyrs.nix`
- `system/keyboard.nix`, `system/upower.nix`
- `system/maintenance.nix` (fstrim, universal SSD trim), `system/maintenance-smartd.nix` (smartd health monitoring, desktop-only), `system/maintenance-disk-alert.nix` (root filesystem usage alert; aurelius only), `system/backup-service.nix`
- `system/docker-health-check.nix` (unhealthy container logging timer; aurelius only)
- `system/packages-system-tools.nix`, `system/packages-server-tools.nix`

## modules/desktops/

| File | Published lower-level modules | Composites |
|------|-------------------------------|-----------|
| `hyprland-standalone.nix` | `flake.modules.nixos.desktop-hyprland-standalone`, `flake.modules.homeManager.desktop-hyprland-standalone` | hyprland standalone session (current predator selection) |

## modules/users/

- `modules/users/higorprado.nix` — tracked user identity, canonical `username`, base NixOS user publisher, and base Home Manager module publisher

## private/

- `private/users/higorprado/default.nix.example` (tracked) — shape for the gitignored Home Manager override entry point at the same path without `.example`
- `private/users/higorprado/*.nix.example` (tracked) — shapes for modular user-private config (env, git, paths, ssh, theme-paths)
- `private/hosts/predator/default.nix.example` (tracked) — shape for the predator host-private entry point at the same path without `.example`
- `private/hosts/predator/auth.nix.example` (tracked) — shape for the predator host-private auth override
- `private/hosts/aurelius/default.nix.example` (tracked) — shape for the aurelius host-private entry point at the same path without `.example`
- `private/hosts/cerebelo/default.nix.example` (tracked) — shape for the cerebelo host-private entry point at the same path without `.example`

## lib/

- `lib/_helpers.nix` — small generic helper set (`portalExecPath`, `portalPathOverrides`)
- `lib/mutable-copy.nix` — helper for copy-once mutable config provisioning in HM activations
## config/desktops/

- `config/desktops/hyprland-standalone/` — tracked Hyprland Lua entrypoint, module tree, and helper scripts provisioned copy-once by `modules/desktops/hyprland-standalone.nix`

## config/apps/

- `config/apps/git/` — tracked Git global ignore payload provisioned by `modules/features/shell/git-gh.nix`
- `config/apps/nvim/` — tracked Neovim config payload
- `config/apps/zen/sync-catppuccin-theme.sh` — tracked shell payload used by
  `modules/features/desktop/theme-zen.nix` to sync Catppuccin assets into the
  live Zen profile during HM activation
- `config/apps/waybar/` — tracked Waybar config and style templates provisioned by copy-once
- `config/apps/htop/` — tracked htoprc provisioned by copy-once
- `config/apps/logid/` — tracked LogiOps config provisioned by copy-once
- `config/apps/mpd/` — tracked MPD config provisioned by copy-once
- `config/apps/rmpc/` — tracked rmpc config provisioned by copy-once
- `config/apps/waypaper/` — tracked Waypaper config template provisioned by copy-once
- `config/apps/walker/` — tracked Walker config template and Catppuccin theme sync payload for the Walker/Elephant launcher and clipboard stack
- `config/apps/elephant/` — tracked Elephant backend config and menu templates provisioned by copy-once

## docs/for-agents/archive/

- `archive/plans/` — completed execution plans no longer needed as active guides
- `archive/log-tracks/` — completed progress logs kept only as historical record
- `archive/reports/` — audit and diagnostic reports

## docs/for-agents active work

- `plans/` — scaffolds plus genuinely active execution plans
- `current/` — scaffolds plus genuinely active progress logs

## Feature-private underscore files

Files prefixed with `_` under `modules/features/` are skipped by auto-import
and are owned by the adjacent feature. Current example:

- `modules/features/shell/_starship-settings.nix` — starship config data used only by
  `modules/features/shell/starship.nix`
- `modules/features/desktop/_theme-catalog.nix` — shared catppuccin theme constants/catalog values (flavor, accent, GTK theme, cursor, icon, font) used by `modules/features/desktop/theme-base.nix`, `modules/features/desktop/regreet.nix`, `modules/features/desktop/theme-zen.nix`, and `modules/features/desktop/walker.nix`
- `modules/features/desktop/_papirus-tray-patched.nix` — feature-private icon-theme derivation helper used by `modules/features/desktop/_theme-catalog.nix` to keep tray symbolic icons color-stable in Waybar

## hardware/predator/

```
default.nix              thin entry: imports hardware/*, boot.nix, performance.nix, …
hardware-configuration.nix  nixos-generate-config output
disko.nix                disk layout (btrfs, LUKS)
hardware/
  gpu-nvidia.nix         NVIDIA RTX 4060 Max-Q config
  laptop-acer.nix        linuwu-sense, platform profile, blacklists
  peripherals-logi.nix   LogiOps, logid service, udev rules
  audio-pipewire.nix     WirePlumber HDMI audio rules
  encryption.nix         TPM2+LUKS, swap, resume
boot.nix                 GRUB+EFI boot loader
performance.nix          OOM, sysctl, ananicy, CPU governor, nix daemon scheduling
impermanence.nix         persistent machine state for predator
persisted-paths.nix      declared persisted directories/files for predator
root-reset.nix           initrd root-subvolume reset for predator
```

## hardware/cerebelo/

```
default.nix              thin entry: imports board.nix, hardware-configuration.nix, performance.nix, and private override
board.nix                Orange Pi 5 (RK3588S) board config: extlinux boot loader + device tree overlays
hardware-configuration.nix  nixos-generate-config output (NVMe root, no /boot/firmware mount)
performance.nix          CPU governor, sysctl tweaks for RK3588S
storage-identifiers.nix  NVMe root UUID — sourced by default.nix for kernelParams
```
