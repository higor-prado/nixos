# Fix: UWSM session crash — graphical-session.target conflict

## Root Cause

Logs mostram:
```
uwsm[...]: A compositor or graphical-session* target is already active!
```

O que acontece:
1. greetd abre sessao para o usuario
2. systemd user instance inicia com default target
3. HM `wayland.windowManager.hyprland.systemd.enable` (default `true`) configura
   `hyprland-session.target` como `WantedBy = [ "graphical-session.target" ]`
4. systemd ativa `graphical-session.target` automaticamente
5. UWSM roda, detecta que `graphical-session.target` ja esta ativo, e **recusa** a iniciar
6. Sessao morre, greetd volta ao greeter

**O conflito**: `withUWSM = true` (NixOS) + `systemd.enable = true` (HM, default) = dois gerentes
de session target brigando pelo `graphical-session.target`.

## Fix

**Um arquivo, uma linha**: `modules/features/desktop/hyprland.nix`

```nix
wayland.windowManager.hyprland = {
  enable = true;
  systemd.enable = false;   # UWSM manages the session targets
  extraConfig = "source = ~/.config/hypr/user.conf";
};
```

`systemd.enable = false` desliga o `hyprland-session.target` e a integracao systemd do HM.
UWSM ja cuida de tudo: ativa `graphical-session.target`, `wayland-session@Hyprland.target`,
exporta env vars, etc.

## Validation

```bash
nix eval path:$PWD#nixosConfigurations.predator.config.system.stateVersion
nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel
```

Apos switch + login com "Hyprland (uwsm-managed)":
```
systemctl --user show-environment | grep UWSM   # UWSM_START_FULL=...
systemctl --user status hypridle.service         # active
```
