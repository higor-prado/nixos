# Add a Desktop Experience

A desktop experience is a top-level dendritic module in `modules/desktops/`
that publishes the lower-level modules for a concrete desktop setup.

## 1. Create the composition file

Create a new file in modules/desktops/ (e.g. modules/desktops/my-desktop.nix):

```nix
{ ... }:
{
  flake.modules.nixos.desktop-my-desktop = { lib, pkgs, ... }: {
    services.greetd.enable = lib.mkDefault true;
    xdg.portal.extraPortals = lib.mkDefault [ pkgs.xdg-desktop-portal-gtk ];
    custom.niri.standaloneSession = false;
  };

  flake.modules.homeManager.desktop-my-desktop = { lib, ... }: {
    # Optional mutable config provisioning for this composition
  };
}
```

## 2. Add to host

In `modules/hosts/<host>.nix`, import the composition modules alongside the
feature modules it configures:

```nix
let
  inherit (config.flake.modules) nixos homeManager;
in
{
  imports = [
    nixos.desktop-my-desktop
    nixos.niri
  ];

  home-manager.users.${userName}.imports = [
    homeManager.desktop-my-desktop
    homeManager.niri
  ];
}
```

## 3. Verify

```bash
nix eval path:$PWD#nixosConfigurations.<host>.config.system.build.toplevel.drvPath
./scripts/check-desktop-composition-matrix.sh
```
