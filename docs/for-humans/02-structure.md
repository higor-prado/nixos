# Repository Structure

```
modules/features/   53+ feature aspects grouped by category
modules/desktops/   2 concrete desktop compositions
modules/hosts/      one file per host (includes + host nixos config)
modules/den.nix     den flake module import
modules/lib/        module/den internals (currently den-host-context.nix)
private/            private overrides
lib/                generic helper functions reused by tracked modules
hardware/<name>/       hardware, disko, boot, overlays (host-specific)
pkgs/               custom packages (linuwu-sense, etc.)
config/             app config files and helper payloads (nvim, tmux, logid, zen, devenv templates)
scripts/            validation gates
tests/              fixtures and test runners
```

## Feature aspects

Each tracked feature file in `modules/features/<category>/` is a self-contained den aspect. Features
with home-manager config use both `.nixos` and `.homeManager` classes:

```nix
{ ... }:
{
  den.aspects.my-feature = {
    nixos = { config, lib, pkgs, ... }: { /* NixOS config */ };
    homeManager = { pkgs, ... }: { /* HM config — auto-routed by den */ };
  };
}
```

Files prefixed with `_` are skipped by den's auto-discovery (e.g. `shell/_starship-settings.nix`).

Root `lib/` is for generic helper functions. `modules/lib/` is only for module/den
internals, not general-purpose helpers.

## Desktop compositions

`modules/desktops/` files own the baseline for a concrete desktop experience.
Each is a den aspect named `desktop-*`, and hosts include them alongside the
feature aspects they parameterize.

## Host files

`modules/hosts/<name>.nix` declares which features the host includes:

```nix
den.aspects.<name> = {
  includes = with den.aspects; [ feature-a feature-b desktop-dms-on-niri ];
  nixos = { ... }: { imports = [ ../../hardware/<name>/default.nix ]; };
};
```

## Hardware files

`hardware/<name>/` contains machine-specific configs that cannot be generalized:
hardware-configuration.nix, disko.nix, hardware/, boot.nix, overlays.nix.
