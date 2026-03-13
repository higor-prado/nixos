# Repository Map

Authoritative map of where things live in this den-native repository.

## Top-level layout

```
modules/features/   53+ feature aspects grouped under category folders
modules/desktops/   2 concrete desktop compositions
modules/hosts/      one file per host
modules/den.nix     den flake module import
modules/lib/        module/den internals (currently den-host-context.nix)
private/            private overrides (gitignored)
hardware/<name>/       machine-specific: hardware, disko, boot, overlays
lib/                generic helper functions (_helpers.nix, mutable-copy.nix, primary-tracked-user.nix)
pkgs/               custom packages
config/             app config files and helper payloads (nvim, tmux, logid, zen, devenv templates)
scripts/            validation gate scripts
tests/              fixtures and test runners
docs/for-agents/archive/ archived plans and log tracks
```

## modules/features/ — category layout

**Core**
- `core/user-context.nix` — `custom.user.name` contract
- `core/host-contracts.nix` — `custom.host.role` contract
- `core/system-base.nix` — base NixOS system config
- `core/nix-settings.nix` — nix daemon settings
- `core/home-manager-settings.nix` — HM framework settings

**Shell / Terminal**
- `shell/fish.nix` — fish shell + zoxide + abbreviations
- `shell/terminal.nix` — TERMINAL env var
- `shell/starship.nix` — starship prompt
- `shell/terminal-tmux.nix` — tmux with tmux-cpu plugin
- `shell/terminals.nix` — foot, ghostty, kitty, alacritty, wezterm
- `shell/git-gh.nix` — git + gh CLI config
- `shell/cli-base.nix` — essential CLI tools
- `shell/tui-tools.nix` — bundled TUI ergonomics (lazygit, lazydocker, yazi, zellij)
- `shell/monitoring-tools.nix` — htop, btop, bottom, fastfetch

**Desktop**
- `desktop/niri.nix` — Niri Wayland compositor
- `desktop/dms.nix` — Dank Material Shell greeter
- `desktop/dms-wallpaper.nix` — DMS wallpaper management
- `desktop/desktop-base.nix`, `desktop/desktop-apps.nix`, `desktop/viewers.nix`, `desktop/gnome-keyring.nix`
- `desktop/theme.nix` — public theme composition
- `desktop/theme-base.nix`, `desktop/theme-zen.nix` — internal theme ownership split
- `desktop/packages-fonts.nix` — Nerd fonts
- `desktop/media-cava.nix`, `desktop/media-tools.nix`, `desktop/music-client.nix`, `desktop/nautilus.nix`
- `desktop/wayland-tools.nix`, `desktop/xwayland.nix`, `desktop/fcitx5.nix`

**Dev / Editors / LLM**
- `dev/editor-neovim.nix` — Neovim + LSP packages + nvim config sync
- `dev/editor-vscode.nix` — VS Code with extensions
- `dev/editor-emacs.nix` — Emacs (pgtk) + Doom env + socket daemon
- `dev/editor-zed.nix` — Zed editor
- `dev/dev-tools.nix`, `dev/dev-devenv.nix`
- `dev/packages-toolchains.nix`, `dev/packages-docs-tools.nix`
- `dev/llm-agents.nix` — host-owned LLM/code-agent package selections

**System**
- `system/networking*.nix`, `system/security.nix`, `system/ssh.nix`
- `system/audio.nix`, `system/bluetooth.nix`, `system/tailscale.nix`
- `system/docker.nix`, `system/podman.nix`, `system/keyrs.nix`
- `system/keyboard.nix`, `system/upower.nix`
- `system/maintenance.nix`, `system/backup-service.nix`
- `system/filesystem-tools.nix`, `system/server-cli-tools.nix`

## modules/desktops/

| File | Aspect name | Composites |
|------|-------------|-----------|
| `dms-on-niri.nix` | `desktop-dms-on-niri` | niri + dms + xdg-user-dirs + … |
| `niri-standalone.nix` | `desktop-niri-standalone` | niri standalone session |

## modules/lib/

- `den-host-context.nix` — schema extension for den host context (`inputs`,
  `customPkgs`, semantic `llmAgents`)

## private/

- higorprado.nix (gitignored) — personal home-manager overrides
- higorprado/ (gitignored) — modular private config (env, git, paths, ssh, theme-paths)

## lib/

- `lib/_helpers.nix` — small generic helper set (currently `portalExecPath`)
- `lib/mutable-copy.nix` — helper for copy-once mutable config provisioning in HM activations
- `lib/primary-tracked-user.nix` — helper that derives the sole tracked host user from den host user membership

## config/apps/

- `config/apps/nvim/` — tracked Neovim config payload
- `config/apps/zen/sync-catppuccin-theme.sh` — tracked shell payload used by
  `modules/features/desktop/theme-zen.nix` to sync Catppuccin assets into the
  live Zen profile during HM activation

## docs/for-agents/archive/

- `archive/plans/` — completed execution plans no longer needed as active guides
- `archive/log-tracks/` — completed progress logs kept only as historical record

## Feature-private underscore files

Files prefixed with `_` under `modules/features/` are skipped by den auto-discovery
and are owned by the adjacent feature. Current example:

- `modules/features/shell/_starship-settings.nix` — starship config data used only by
  `modules/features/shell/starship.nix`

## hardware/predator/

```
default.nix              thin entry: imports hardware/*, boot.nix, overlays.nix, …
hardware-configuration.nix  nixos-generate-config output
disko.nix                disk layout (btrfs, LUKS)
hardware/
  gpu-nvidia.nix         NVIDIA RTX 4060 Max-Q config
  laptop-acer.nix        linuwu-sense, platform profile, blacklists
  peripherals-logi.nix   LogiOps, logid service, udev rules
  audio-pipewire.nix     WirePlumber HDMI audio rules
  encryption.nix         TPM2+LUKS, swap, resume
boot.nix                 GRUB+EFI boot loader
overlays.nix             khal, dsearch fixes
packages.nix             predator-specific packages
performance.nix          OOM, sysctl, ananicy, smartd, CPU governor
```
