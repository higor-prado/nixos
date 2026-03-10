# Add a Desktop Experience

A desktop experience is a den aspect in `modules/desktops/` that owns the
composition baseline for a concrete desktop setup.

## 1. Create the composition file

Create a new file in modules/desktops/ (e.g. modules/desktops/my-desktop.nix):

```nix
{ ... }:
{
  den.aspects.desktop-my-desktop = {
    nixos = { config, lib, pkgs, ... }: {
      imports = [
        ({ ... }: {
          services.greetd.enable = lib.mkDefault true;
          xdg.portal.extraPortals = lib.mkDefault [ pkgs.xdg-desktop-portal-gtk ];
        })
        {
          config.custom.niri.standaloneSession = false;
        }
      ];
    };

    homeManager = { lib, ... }: {
      # Optional mutable config provisioning for this composition
    };
  };
}
```

## 2. Add to host

In `modules/hosts/<host>.nix`, add the composition aspect alongside the
feature aspects it configures:

```nix
includes = with den.aspects; [
  # ...
  desktop-my-desktop
  niri
  desktop-base
  # ...
];
```

## 3. Verify

```bash
nix eval path:$PWD#nixosConfigurations.<host>.config.system.build.toplevel.drvPath
./scripts/check-desktop-composition-matrix.sh
```
