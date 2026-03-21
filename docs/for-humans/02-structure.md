# Repository Structure

```
modules/features/   53+ feature modules grouped by category
modules/desktops/   2 concrete desktop compositions
modules/hosts/      host owner files with concrete composition
modules/nixos.nix   structural NixOS runtime surface
modules/flake-parts.nix enables `flake.modules.*`
modules/users/      tracked user owner modules; `higorprado.nix` also owns `username`
modules/systems.nix supported flake systems
modules/templates.nix flake template outputs
private/            private overrides
lib/                generic helper functions reused by tracked modules
hardware/<name>/    hardware, disko, boot, persistence/reset (host-specific)
pkgs/               custom packages (linuwu-sense, etc.)
config/             app config files and helper payloads (nvim, tmux, logid, zen, devenv templates)
scripts/            validation gates
tests/              fixtures and test runners
```

## Feature modules

Each tracked feature file in `modules/features/<category>/` is a top-level
dendritic module that publishes lower-level NixOS and/or Home Manager modules:

```nix
{ ... }:
{
  flake.modules.nixos.my-feature = { config, lib, pkgs, ... }: { /* NixOS config */ };
  flake.modules.homeManager.my-feature = { pkgs, ... }: { /* HM config */ };
}
```

Files prefixed with `_` are skipped by auto-import (for example
`shell/_starship-settings.nix`).

Root `lib/` is for generic helper functions. `modules/nixos.nix`,
`modules/flake-parts.nix`, and `modules/users/higorprado.nix` are runtime
surfaces, not general-purpose helpers.

## Desktop compositions

`modules/desktops/` files publish `flake.modules.nixos.desktop-*` and, when
needed, `flake.modules.homeManager.desktop-*` for a concrete desktop
experience.

## Host files

`modules/hosts/<name>.nix` declares one concrete configuration:

```nix
let
  inherit (config.flake.modules) nixos homeManager;
in
{
  configurations.nixos.<name>.module = {
    imports = [ nixos.my-feature ];
    home-manager.users.${userName}.imports = [ homeManager.my-feature ];
  };
}
```

## Hardware files

`hardware/<name>/` contains machine-specific configs that cannot be generalized:
hardware-configuration.nix, disko.nix, hardware/, boot.nix, persistence/reset.
Host-specific package overlays do not belong there.
