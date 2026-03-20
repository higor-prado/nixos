# Repository Structure

```
modules/features/   53+ feature modules grouped by category
modules/desktops/   2 concrete desktop compositions
modules/hosts/      one file per host inventory + concrete configuration
modules/den.nix     shrinking den compatibility import
modules/lib/        repo/runtime bridge internals
private/            private overrides
lib/                generic helper functions reused by tracked modules
hardware/<name>/    hardware, disko, boot, overlays (host-specific)
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

Root `lib/` is for generic helper functions. `modules/lib/` is only for
repo/runtime bridge internals, not general-purpose helpers.

## Desktop compositions

`modules/desktops/` files publish `flake.modules.nixos.desktop-*` and, when
needed, `flake.modules.homeManager.desktop-*` for a concrete desktop
experience.

## Host files

`modules/hosts/<name>.nix` declares host inventory and one concrete
configuration:

```nix
{
  repo.hosts.<name> = {
    system = "x86_64-linux";
    role = "desktop";
    trackedUsers = [ "higorprado" ];
  };

  configurations.nixos.<name>.module = {
    imports = [ config.flake.modules.nixos.my-feature ];
    home-manager.users.${user.userName}.imports = [
      config.flake.modules.homeManager.my-feature
    ];
  };
}
```

## Hardware files

`hardware/<name>/` contains machine-specific configs that cannot be generalized:
hardware-configuration.nix, disko.nix, hardware/, boot.nix, overlays.nix.
