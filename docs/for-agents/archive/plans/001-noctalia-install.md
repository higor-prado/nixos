# Noctalia Install

## Goal

Adicionar Noctalia como shell Wayland alternativo para o host predator, em
composição paralela ao DMS existente. Todos os módulos DMS permanecem no repo
sem alteração. A configuração nixos `predator-noctalia` permite testar e
migrar para Noctalia; o `predator` original continua avaliando com DMS.

## Scope

In scope:
- Flake input `noctalia-shell`
- `modules/features/desktop/noctalia.nix` (nixos + homeManager sides)
- `modules/desktops/noctalia-on-niri.nix` + `config/desktops/noctalia-on-niri/custom.kdl`
- `configurations.nixos.predator-noctalia` em `modules/hosts/predator.nix`
- Backup de `~/.config/niri/custom.kdl` antes do test switch

Out of scope:
- Qualquer modificação em dms.nix, dms-wallpaper.nix, dms-on-niri.nix, settings.json
- Migração permanente do host (decisão do usuário após testes)
- Configuração de tema/colorschemes Noctalia
- Plugins Noctalia

## Current State

- `flake.nix`: input `nixpkgs` → `github:NixOS/nixpkgs/nixos-unstable` (único
  nixpkgs, sem alias unstable separado)
- `modules/desktops/dms-on-niri.nix`: provisions `config/desktops/dms-on-niri/custom.kdl`
  → `~/.config/niri/custom.kdl` via copy-once
- `config/desktops/dms-on-niri/custom.kdl`: inclui dms/*.kdl, spawna `dms run`,
  usa `dms ipc` para áudio/brilho/lock/launcher/media; layer-rule swww-daemon backdrop
- `modules/features/desktop/dms-wallpaper.nix`: serviços awww-daemon + dms-awww;
  noctalia gerencia wallpaper internamente — esses serviços não entram na composição noctalia
- `configurations.nixos.predator`: usa nixos.dms, nixos.desktop-dms-on-niri,
  homeManager.dms, homeManager.dms-wallpaper

## Desired End State

- `nix eval .#nixosConfigurations.predator-noctalia.config.system.build.toplevel` → ok
- `nix eval .#nixosConfigurations.predator.config.system.build.toplevel` → ok (DMS intacto)
- `nh os test path:$HOME/nixos#predator-noctalia` aplica e noctalia sobe no login Niri

## Phases

### Phase 0: Baseline

Validation:
- `nix eval .#nixosConfigurations.predator.config.system.build.toplevel` → ok
- `./scripts/run-validation-gates.sh predator` → ok

### Phase 1: Flake input

Targets:
- `flake.nix`

Changes:
Adicionar ao bloco `inputs` (antes do fechamento `}`):
```nix
noctalia-shell = {
  url = "github:noctalia-dev/noctalia-shell";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

Validation:
- `nix flake lock --update-input noctalia-shell`
- `nix eval .#nixosConfigurations.predator.config.system.build.toplevel` → ainda ok

Diff expectation:
- `flake.nix`: +4 linhas; `flake.lock`: novo entry `noctalia-shell`

Commit target:
- `feat(flake): add noctalia-shell input`

### Phase 2: Feature module noctalia.nix

Targets:
- `modules/features/desktop/noctalia.nix` (novo)

Changes:
```nix
{ inputs, ... }:
{
  flake.modules = {
    nixos.noctalia =
      { lib, ... }:
      {
        services.upower.enable = lib.mkDefault true;
        services.power-profiles-daemon.enable = lib.mkDefault true;
      };

    homeManager.noctalia =
      { pkgs, ... }:
      {
        home.packages = [ inputs.noctalia-shell.packages.${pkgs.stdenv.hostPlatform.system}.default ];
      };
  };
}
```

Validation:
- `git add modules/features/desktop/noctalia.nix`
- `nix eval .#nixosConfigurations.predator.config.system.build.toplevel` → ok
  (módulo não está composto no predator ainda, só verifica que o repo avalia)

Diff expectation:
- 1 novo arquivo, ~20 linhas

Commit target:
- `feat(noctalia): add noctalia feature module`

### Phase 3: Desktop composition noctalia-on-niri

Targets:
- `modules/desktops/noctalia-on-niri.nix` (novo)
- `config/desktops/noctalia-on-niri/custom.kdl` (novo)

**`modules/desktops/noctalia-on-niri.nix`:**
Espelhar `dms-on-niri.nix`, trocando nome da activation e path do source kdl:
```nix
{ config, ... }:
let
  userName = config.username;
in
{
  flake.modules = {
    nixos.desktop-noctalia-on-niri =
      { lib, pkgs, ... }:
      {
        services.greetd.enable = lib.mkDefault true;
        services.greetd.settings.default_session.command =
          lib.mkOverride 2000 "/run/current-system/sw/bin/true";
        services.greetd.settings.default_session.user =
          lib.mkOverride 2000 userName;
        systemd.user.services.niri-flake-polkit.enable = lib.mkDefault false;
        xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
      };

    homeManager.desktop-noctalia-on-niri =
      { lib, ... }:
      let
        mutableCopy = import ../../lib/mutable-copy.nix { inherit lib; };
        helpers = import ../../lib/_helpers.nix;
      in
      {
        xdg.configFile = helpers.portalPathOverrides;

        home.activation.provisionNoctaliaOnNiriCustom = lib.hm.dag.entryAfter [ "writeBoundary" ] (
          mutableCopy.mkCopyOnce {
            source = ../../config/desktops/noctalia-on-niri/custom.kdl;
            target = "$HOME/.config/niri/custom.kdl";
          }
        );
      };
  };
}
```

**`config/desktops/noctalia-on-niri/custom.kdl`:**
Derivado do DMS custom.kdl com as seguintes mudanças:

1. Remover as 6 linhas `include "dms/..."` do topo
2. Trocar spawn:
   - Remover: `spawn-at-startup "dms" "run"`
   - Adicionar: `spawn-at-startup "noctalia-shell"`
3. Manter: `spawn-at-startup "xwayland-satellite"`
4. Trocar keybinds DMS IPC por alternativas genéricas (refinar com `qs ipc show` pós-instalação):
   - Launcher: `spawn "qs" "-c" "noctalia-shell" "ipc" "call" "launcher" "toggle"`
   - Lock: `spawn "qs" "-c" "noctalia-shell" "ipc" "call" "lockscreen" "lock"`
   - Volume:
     ```kdl
     XF86AudioRaiseVolume allow-when-locked=true { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "3%+"; }
     XF86AudioLowerVolume allow-when-locked=true { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "3%-"; }
     XF86AudioMute allow-when-locked=true { spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle"; }
     XF86AudioMicMute allow-when-locked=true { spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SOURCE@" "toggle"; }
     ```
   - Brightness:
     ```kdl
     XF86MonBrightnessUp allow-when-locked=true { spawn "brightnessctl" "set" "5%+"; }
     XF86MonBrightnessDown allow-when-locked=true { spawn "brightnessctl" "set" "5%-"; }
     ```
   - Media (playerctl):
     ```kdl
     XF86AudioPlay allow-when-locked=true { spawn "playerctl" "play-pause"; }
     XF86AudioPause allow-when-locked=true { spawn "playerctl" "play-pause"; }
     XF86AudioNext allow-when-locked=true { spawn "playerctl" "next"; }
     XF86AudioPrev allow-when-locked=true { spawn "playerctl" "previous"; }
     ```
5. Trocar layer-rule wallpaper:
   - Remover: `layer-rule { match namespace="^swww-daemon$"; place-within-backdrop true; }`
   - Adicionar (wallpaper estacionário, opção 2 da doc noctalia):
     ```kdl
     layer-rule {
       match namespace="^noctalia-wallpaper*"
       place-within-backdrop true
     }
     layout {
       background-color "transparent"
     }
     ```
6. Adicionar regras noctalia/niri:
   ```kdl
   debug {
     honor-xdg-activation-with-invalid-serial
   }
   ```
   (geometry-corner-radius no window-rule já existe em 12; noctalia recomenda 20 —
   ajustar por preferência pessoal)

Nota copy-once: se `~/.config/niri/custom.kdl` já existe, o activation não
sobrescreve. Antes do Phase 5:
```bash
cp ~/.config/niri/custom.kdl ~/.config/niri/custom.kdl.dms-backup
rm ~/.config/niri/custom.kdl
```

Validation:
- `git add modules/desktops/noctalia-on-niri.nix config/desktops/noctalia-on-niri/`
- `nix eval .#nixosConfigurations.predator.config.system.build.toplevel` → ok

Diff expectation:
- 2 novos arquivos

Commit target:
- `feat(noctalia): add noctalia-on-niri desktop composition`

### Phase 4: predator-noctalia configuration

Targets:
- `modules/hosts/predator.nix`

Changes:
Ler `modules/hosts/predator.nix` para entender a estrutura de slices (variáveis
locais ou inline). Adicionar bloco `configurations.nixos.predator-noctalia`
mantendo o `predator` original intocado. O novo bloco:

- Herda todos os slices compartilhados (niri, xwayland, gnome-keyring,
  keyrs, nautilus, fcitx5, wayland-tools, theme-base, theme-zen, media-cava,
  media-tools, music-client)
- Substitui no nixos slice:
  - Remove: `nixos.desktop-dms-on-niri`, `nixos.dms`
  - Adiciona: `nixos.desktop-noctalia-on-niri`, `nixos.noctalia`
- Substitui no hm slice:
  - Remove: `homeManager.desktop-dms-on-niri`, `homeManager.dms`, `homeManager.dms-wallpaper`
  - Adiciona: `homeManager.desktop-noctalia-on-niri`, `homeManager.noctalia`
- Verificar se `inputs.dms.nixosModules.*` são necessários na predator-noctalia
  (se forem importados via nixosDesktopNiri compartilhado, podem precisar ser
  mantidos ou movidos para o bloco predator original somente)

Validation:
- `nix eval .#nixosConfigurations.predator-noctalia.config.system.build.toplevel` → ok
- `nix eval .#nixosConfigurations.predator.config.system.build.toplevel` → ok
- `./scripts/run-validation-gates.sh predator` → ok

Diff expectation:
- `predator.nix`: +~40 linhas (novo bloco predator-noctalia)

Commit target:
- `feat(noctalia): add predator-noctalia nixos configuration`

### Phase 5: Test switch

```bash
# Backup obrigatório (copy-once não sobrescreve arquivo existente)
cp ~/.config/niri/custom.kdl ~/.config/niri/custom.kdl.dms-backup
rm ~/.config/niri/custom.kdl

# Build + activate sem marcar como boot default
nh os test path:$HOME/nixos#predator-noctalia

# Verificar que noctalia subiu
journalctl --user -u niri --no-pager -n 50
```

Se ok → switch permanente:
```bash
nh os switch path:$HOME/nixos#predator-noctalia
```

Se falhar → rollback:
```bash
cp ~/.config/niri/custom.kdl.dms-backup ~/.config/niri/custom.kdl
nh os switch path:$HOME/nixos#predator
```

Pós-switch — descobrir IPC commands para refinar keybinds:
```bash
qs -c noctalia-shell ipc show
```
Atualizar `~/.config/niri/custom.kdl` com os comandos corretos e propagar
para `config/desktops/noctalia-on-niri/custom.kdl` (para futuros rebuilds).

## Risks

- **IPC commands noctalia**: comandos exatos de `qs ipc` para áudio/brilho/lock/launcher
  não confirmados antes da instalação. wpctl/brightnessctl/playerctl funcionam como
  fallback imediato.

- **copy-once conflito**: `~/.config/niri/custom.kdl` já existe (DMS); backup + rm
  obrigatório antes do Phase 5, senão o template noctalia não é copiado.

- **power-profiles-daemon**: verificar conflito com tlp se estiver ativo no host.

- **inputs.dms modules**: `dank-material-shell` e `greeter` nixosModules do DMS
  podem estar importados no bloco compartilhado de predator.nix — ler antes de
  montar predator-noctalia para saber se precisam ser isolados no bloco predator.

## Definition of Done

- Branch `feat/noctalia` com commits das Phases 1–4
- `nix eval .#nixosConfigurations.predator-noctalia` avalia ok
- `nix eval .#nixosConfigurations.predator` avalia ok
- Phase 5 executado: noctalia visível e funcional na sessão Niri
- Keybinds de áudio/brilho/lock/launcher operacionais
