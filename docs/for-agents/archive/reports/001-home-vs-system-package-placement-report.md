# Home vs System Package Placement Report

## Status

Completed

## Scope and method

- Read the operating docs in `docs/for-agents/000-006.md` and `999-lessons-learned.md`.
- Read all **tracked** `.nix` files in the repo.
- Per `docs/for-agents/004-private-safety.md`, private override files under `private/` were **not** read.
- Ran `./scripts/run-validation-gates.sh structure` after producing this report context.

## Executive summary

The repo already has a strong architectural pattern:

- `modules/hosts/*.nix` decide what each machine imports.
- `modules/features/**/*.nix` publish reusable lower-level NixOS and/or Home Manager modules.
- `hardware/<host>/` owns machine support.
- Home Manager is wired explicitly per host.

The part that is still fuzzy is **package ownership**.
Today, package placement follows a real logic, but that logic is only partially explicit:

- **NixOS** is usually used for things that affect the machine, login/session plumbing, services, drivers, fonts, firewall, PAM, containers, and a few package bundles.
- **Home Manager** is usually used for user apps, CLI UX, editor config, shell config, desktop config, and user services.
- Some features are intentionally **split** between both layers when one capability needs system plumbing plus user configuration.

The discomfort comes from the exceptions: there are several modules where packages are placed in NixOS even though they are primarily user tools, and a few host/hardware files also carry package policy. That makes the decision boundary feel based on history instead of an obvious rule.

## The current logic that is actually present in the repo

## 1. Host composition is already explicitly split by layer

The clearest signal in the repo is in the host files:

- `modules/hosts/predator.nix`
- `modules/hosts/aurelius.nix`
- `modules/hosts/cerebelo.nix`

Each host keeps separate lists for:

- NixOS infrastructure/core/desktop/user-tool imports
- Home Manager user-tool/shell/desktop/dev imports

So the repo is already modeling two different ownership planes:

- **machine/runtime plane**
- **user environment plane**

That is good and should remain the main organizing principle.

## 2. Current NixOS placement pattern

Today, packages or modules land in NixOS when they match one of these patterns:

### A. Machine capability or boot/session plumbing

Examples:

- `modules/features/system/audio.nix`
- `modules/features/system/bluetooth.nix`
- `modules/features/system/networking*.nix`
- `modules/features/system/security.nix`
- `modules/features/system/ssh.nix`
- `modules/features/desktop/niri.nix`
- `modules/features/desktop/fcitx5.nix`
- `modules/features/desktop/gnome-keyring.nix`
- `modules/desktops/*.nix`

These touch things like:

- services
- PAM
- firewall
- portal setup
- display manager / greetd
- kernel modules
- user groups
- systemd system units
- hardware / udev / boot

This is a clean NixOS fit.

### B. Packages required as part of a system-owned capability

Examples:

- `modules/features/system/networking-wireguard-client.nix` adds `wireguard-tools`
- `modules/features/system/networking-wireguard-server.nix` adds `wireguard-tools`
- `modules/features/system/podman.nix` adds `distrobox`
- `modules/features/system/attic-client.nix` adds `attic-client`
- `modules/features/desktop/packages-fonts.nix` adds fonts
- `modules/features/desktop/niri.nix` adds `xwayland-satellite`

This is a mixed bucket. Some of these are truly system-adjacent; some are more user-facing.

### C. Shared package bundles intended to be available everywhere on a host

Examples:

- `modules/features/system/packages-system-tools.nix`
- `modules/features/system/packages-server-tools.nix`
- `modules/features/dev/packages-toolchains.nix`
- `modules/features/dev/packages-docs-tools.nix`

This is the main source of ambiguity.
These bundles are in NixOS mostly because they are treated as host-wide defaults, not because the tools are intrinsically system-owned.

## 3. Current Home Manager placement pattern

Today, packages or modules land in Home Manager when they match one of these patterns:

### A. User application or CLI UX

Examples:

- `modules/features/shell/core-user-packages.nix`
- `modules/features/shell/tui-tools.nix`
- `modules/features/dev/dev-tools.nix`
- `modules/features/dev/llm-agents.nix`
- `modules/features/desktop/desktop-apps.nix`
- `modules/features/desktop/media-tools.nix`
- `modules/features/desktop/wayland-tools.nix`
- `modules/features/desktop/desktop-viewers.nix`

These are classic HM cases: tools used by the tracked user, not by the machine.

### B. User configuration of a program

Examples:

- `modules/features/shell/fish.nix`
- `modules/features/shell/starship.nix`
- `modules/features/shell/git-gh.nix`
- `modules/features/shell/terminal-tmux.nix`
- `modules/features/shell/terminals.nix`
- `modules/features/dev/editor-vscode.nix`
- `modules/features/dev/editor-emacs.nix`
- `modules/features/dev/editor-neovim.nix`
- `modules/features/desktop/theme-base.nix`
- `modules/features/desktop/theme-zen.nix`

This is also a clean HM fit.

### C. User services and user-state files

Examples:

- `modules/features/system/backup-service.nix`
- `modules/features/desktop/dms-wallpaper.nix`
- `modules/features/desktop/music-client.nix`
- `modules/features/desktop/fcitx5.nix`
- `modules/features/dev/editor-neovim.nix`

These manage:

- `systemd.user.*`
- `xdg.configFile`
- `home.file`
- user session variables
- activation hooks that materialize configs in `$HOME`

Again, clean HM ownership.

## 4. Current split-feature pattern

Several features are already modeled correctly as “one capability, two owners”:

- `fish`: NixOS sets login shell / base availability, HM sets user UX
- `ssh`: NixOS owns daemon, HM owns client config
- `docker`: NixOS owns daemon, HM owns shell ergonomics
- `mosh`: NixOS owns server/firewall, HM owns client package
- `niri`: NixOS owns compositor/portal/session pieces, HM owns config files
- `fcitx5`: NixOS owns IME stack, HM owns user session/autostart/theme integration
- `nautilus`: NixOS owns `gvfs`/`dconf`, HM owns the app and mime defaults
- `editor-neovim`: NixOS owns PAM/session limits, HM owns the editor and toolchain bits
- `dms`: NixOS owns greeter/system integration, HM owns user shell config

This split pattern is good and should become the explicit default for any feature that spans both concerns.

## Where the repo is inconsistent today

## 1. Several user-facing package bundles are in NixOS

### `modules/features/dev/packages-toolchains.nix`

Current contents are mostly developer tools:

- `gcc`
- `nodejs`
- `sqlite`
- `tree-sitter`
- `binutils`
- `gnumake`
- `cmake`
- `libtool`

These are primarily used by the tracked user in shells, editors, dev workflows, and ad-hoc builds.
They do **not** configure the machine.

This is the strongest candidate to be mostly HM-owned.

### `modules/features/dev/packages-docs-tools.nix`

- `ghostscript`
- `tectonic`
- `mermaid-cli`
- `pandoc`

These are also clearly user workflow tools, not machine runtime policy.
Also a strong HM candidate.

### `modules/features/system/packages-server-tools.nix`

This bundle mixes two different kinds of tools:

- user CLI tools: `eza`, `bat`, `fd`, `ripgrep`, `jq`, `yq-go`, `tmux`, `btop`, `ncdu`
- machine/admin tools: `lsof`, `strace`, `bind`, `mtr`, `iperf3`, `tcpdump`

So the ambiguity is real: the file currently combines **operator UX** and **system administration** into one NixOS package set.

### `modules/features/system/attic-client.nix`

This only adds the `attic-client` CLI. The actual publisher logic already references the package directly through Nix paths where needed.
So this module currently behaves more like “operator tool availability” than machine policy.

### `modules/features/system/podman.nix`

`virtualisation.podman` is clearly system-owned.
`distrobox` is a user-facing workflow tool.
That file currently mixes both.

## 2. Some host/hardware files still contain package policy

### `hardware/predator/packages.nix`

This adds:

- `nvtopPackages.nvidia`
- `tpm2-tools`

Both are understandable on Predator, but they are still package policy under `hardware/`, and your own agent docs say package policy should stay out of hardware unless it is directly part of machine support.

This is a structural smell.
Even if the packages remain system-scoped, they would be clearer in:

- a host-owned module under `modules/hosts/`, or
- a reusable feature with an explicit name like `system.packages-hardware-debug`, `desktop.gpu-tools`, or `system.tpm-tools`.

### `hardware/predator/hardware/gpu-nvidia.nix`

This file also sets `nixpkgs.config.allowUnfree = true`, which conflicts with the documented rule that nixpkgs policy belongs in `core/nixpkgs-settings.nix`.

That is not directly about Home vs system packages, but it contributes to the feeling that placement rules are not fully enforced.

## 3. Host-level `environment.systemPackages` is being used for operator tooling

### `modules/hosts/predator.nix`

`extraSystemPackages = [ customPkgs.predator-tui ];`

This looks like an operator-facing program, not a machine runtime dependency.
So it is another example where “put it in system so it exists on the host” won over “who actually owns this tool?”.

## The logic that should become explicit

The cleanest rule for this repo is:

> Put things in **NixOS** when they are owned by the machine.
> Put things in **Home Manager** when they are owned by the user.
> Split the feature when one capability needs both.

That sounds simple, but it becomes much clearer if written as a decision tree.

## Proposed decision tree

### Put it in NixOS if any of these are true

1. It configures or enables a **system service**.
2. It changes **boot**, **kernel**, **drivers**, **firmware**, **udev**, **PAM**, **firewall**, **networking**, **filesystem**, **containers**, or **system users/groups**.
3. It must exist **before login** or independently of any user home.
4. It is needed by **root**, by a **systemd system service**, or by multiple users as machine policy.
5. It is part of a **desktop/session substrate** rather than an application choice.
6. It provides machine-wide assets such as **fonts**, shared portal wiring, global session variables, or `/etc` files.

### Put it in Home Manager if any of these are true

1. It is primarily a **tool or app used by the tracked user**.
2. It lives mostly in the user’s **shell/editor/desktop workflow**.
3. It needs config under `$HOME`, `xdg.configFile`, `home.file`, `home.sessionVariables`, or `systemd.user`.
4. It is a **GUI app**, **CLI app**, **editor**, **prompt**, **theme**, **terminal**, **TUI**, or user-local helper.
5. Another user on the same host might reasonably want a different choice.

### Split the feature if both are true

Examples:

- daemon + client config
- compositor + compositor config
- IME stack + user session integration
- app runtime dependency + app preference/config
- server capability + operator client tool

## The most important normalization for this repo

`environment.systemPackages` should become the **exception**, not the default place for shared package bundles.

A good repo-level rule would be:

> If a package is installed mainly so the tracked user can run it interactively, prefer Home Manager.
> Use `environment.systemPackages` only when the package is part of machine/runtime ownership.

That one sentence would remove most of the ambiguity.

## Recommended target classification for current modules

## Keep in NixOS

These already fit well:

- `modules/features/core/*`
- `modules/features/system/audio.nix`
- `modules/features/system/bluetooth.nix`
- `modules/features/system/networking*.nix`
- `modules/features/system/security.nix`
- `modules/features/system/ssh.nix` (daemon half)
- `modules/features/system/tailscale.nix`
- `modules/features/system/maintenance*.nix`
- `modules/features/system/forgejo.nix`
- `modules/features/system/grafana.nix`
- `modules/features/system/prometheus.nix`
- `modules/features/system/node-exporter.nix`
- `modules/features/system/github-runner.nix`
- `modules/features/system/attic-server.nix`
- `modules/features/system/attic-local-publisher.nix`
- `modules/features/system/attic-publisher.nix`
- `modules/features/system/keyrs.nix`
- `modules/features/desktop/packages-fonts.nix`
- `modules/features/desktop/xwayland.nix`
- desktop/session composition modules under `modules/desktops/`
- host-owned user group entitlements in `modules/hosts/*.nix`
- hardware support in `hardware/*`

## Keep split across NixOS + Home Manager

These already match the repo’s real architecture:

- `fish`
- `ssh`
- `docker`
- `mosh`
- `niri`
- `dms`
- `fcitx5`
- `nautilus`
- `editor-neovim`
- `gaming`
- `keyboard`
- `noctalia`

## Strong candidates to move mostly or fully to Home Manager

### Move to HM

- `modules/features/dev/packages-docs-tools.nix`
- `modules/features/dev/packages-toolchains.nix` package list
- `modules/features/system/attic-client.nix`
- `modules/hosts/predator.nix` → `predator-tui`

### Split into machine-support vs user-tool halves

- `modules/features/system/packages-server-tools.nix`
  - keep admin/network/debug tools in NixOS if desired
  - move general CLI ergonomics to HM

- `modules/features/system/podman.nix`
  - keep Podman enablement in NixOS
  - move `distrobox` to HM unless there is a concrete system-owned need

- `hardware/predator/packages.nix`
  - likely move out of `hardware/`
  - then decide per package:
    - `nvtopPackages.nvidia`: probably HM on desktop
    - `tpm2-tools`: NixOS or HM depending on whether you want it as machine-admin tooling for root or just user CLI

## Suggested naming model to remove ambiguity

Part of the confusion is semantic: some files are named `packages-*` without stating whether they are:

- machine-support packages
- operator/admin packages
- user workflow packages
- desktop app bundles

A clearer naming convention would help a lot.

### For NixOS-owned bundles

Use names that say why the machine owns them:

- `packages-machine-support`
- `packages-admin-debug`
- `packages-runtime-support`
- `packages-network-debug`

### For HM-owned bundles

Use names that say they are user environment choices:

- `cli-base`
- `cli-dev`
- `cli-server-ops`
- `desktop-apps`
- `desktop-media`
- `dev-toolchains`
- `docs-tools`

The repo already does this well in some places:

- `core-user-packages`
- `desktop-apps`
- `dev-tools`

The ambiguous files are mostly the ones still named as generic package buckets under NixOS.

## Proposed repo rule text

A good rule to add to agent/human docs would be something like:

> ### Package ownership rule
> - Prefer **Home Manager** for packages used interactively by the tracked user.
> - Prefer **NixOS** for packages that support machine capabilities, system services, boot/session plumbing, or root/admin workflows that must exist independently of user homes.
> - When one feature needs both, publish both a NixOS and a Home Manager module and wire both explicitly in the host.
> - Avoid generic `environment.systemPackages` bundles for user tooling.
> - Keep package policy out of `hardware/` unless it is inseparable from machine support.

## Bottom line

The repo does **not** have random placement. It already follows this broad logic:

- **system = machine ownership**
- **home = user ownership**
- **split when the capability spans both**

What makes it feel inconsistent is that some older or convenience-driven package bundles still use NixOS as a catch-all for “tools I want on this machine”.

If you tighten the rule to:

> `environment.systemPackages` only for machine-owned/runtime-owned tools,
> and `home.packages` for user-owned interactive tools,

then the decision becomes much more obvious.

## Validation

- `./scripts/run-validation-gates.sh structure` ✅
