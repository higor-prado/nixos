# Remediar gaps de documentação no repo map e reduzir boilerplate de copy-once

## Goal

Corrigir as entradas faltantes e ambíguas no `docs/for-agents/001-repo-map.md`
e reduzir a repetição de boilerplate nos módulos `waybar.nix` e `walker.nix`,
mantendo a filosofia de explicitação do repo.

## Scope

In scope:

- Adicionar `dev/llm-paseo.nix` e `media/aiostreams-tailscale-serve.nix` ao repo map.
- Substituir o glob `system/networking*.nix` por entradas explícitas.
- Extrair helper local de copy-once em `waybar.nix` e `walker.nix` (padrão já usado
  em `hyprland-standalone.nix`).

Out of scope:

- Alterar o `_module.args` do cerebelo (exceção documentada aceita).
- Adicionar check automatizado de completude do repo map (complexidade
  desproporcional para 2 arquivos).
- Refatorar outros módulos além de waybar e walker.

## Current State

### Gaps no repo map

| Arquivo real                           | Categoria | Tipo  | Hosts que importam | Publica                                          |
| -------------------------------------- | --------- | ----- | ------------------ | ------------------------------------------------ |
| `dev/llm-paseo.nix`                    | dev       | HM    | predator           | `flake.modules.homeManager.llm-paseo`            |
| `media/aiostreams-tailscale-serve.nix` | media     | NixOS | cerebelo           | `flake.modules.nixos.aiostreams-tailscale-serve` |

Ambos os arquivos:

- Seguem o padrão dendritic corretamente (publicam em `flake.modules.*`).
- Passam `check-feature-publisher-name-match.sh` (nome do arquivo casa com
  nome publicado).
- São importados explicitamente nas composições de host.
- Não são mencionados em nenhum doc fora de archive.

### Ambigüidade `networking*.nix`

O repo map atual diz:

```
- `system/networking*.nix`, `system/security.nix`, `system/ssh.nix`
```

E depois, separadamente:

```
- `system/networking-wireguard-client.nix`, `system/networking-wireguard-server.nix`
```

O glob `networking*.nix` esconde 3 arquivos que não são listados em nenhum
outro lugar:

- `networking.nix` (importado em todos os 3 hosts — NetworkManager base)
- `networking-avahi.nix` (importado só em predator — mDNS)
- `networking-resolved.nix` (importado em predator e cerebelo — systemd-resolved)

Os dois de WireGuard já estão listados explicitamente, então o glob é
redundante para eles.

### Repetição de copy-once

**waybar.nix** (102 linhas): 7 blocos `home.activation.provisionWaybar*` quase
idênticos. Cada um tem ~8 linhas. Total: ~56 linhas de boilerplate para 7
entradas.

**walker.nix** (167 linhas): 7 blocos `home.activation.provision{Walker,Elephant}*`
quase idênticos. ~56 linhas de boilerplate.

**hyprland-standalone.nix** já usa o padrão de helper local que falta nos outros:

```nix
provisionHyprlandLuaFile = target: source: lib.hm.dag.entryAfter [...] (
  mutableCopy.mkCopyOnce {
    inherit source;
    target = "$HOME/.config/hypr/${target}";
  }
);
```

Os módulos waybar e walker não usam helper nenhum — cada entrada repete a
estrutura completa inline.

## Desired End State

1. `docs/for-agents/001-repo-map.md` lista explicitamente todos os 74 feature
   files (atualmente documenta 72 de 74, com 3 adicionais escondidos atrás de
   glob).
2. `waybar.nix` e `walker.nix` usam helper local para copy-once, reduzindo
   ~90 linhas sem esconder o que está sendo provisionado.
3. `check-docs-drift.sh` continua passando.

## Phases

### Phase 0: Baseline

Validation:

- `./scripts/run-validation-gates.sh structure` — deve passar antes e depois.
- `nix eval path:$PWD#nixosConfigurations.{predator,aurelius,cerebelo}.config.system.stateVersion` — sem alteração de comportamento.

### Phase 1: Corrigir repo map

Targets:

- `docs/for-agents/001-repo-map.md`

Changes:

1. Adicionar `dev/llm-paseo.nix` na seção **Dev / Editors / LLM**:

   ```
   - `dev/llm-paseo.nix` — Paseo LLM agent (getpaseo/paseo)
   ```

2. Adicionar `media/aiostreams-tailscale-serve.nix` na seção **Media**:

   ```
   - `media/aiostreams-tailscale-serve.nix` — Tailscale Serve HTTPS proxy para AIOStreams (cerebelo only)
   ```

3. Substituir o glob na seção **System**:
   De:
   ```
   - `system/networking*.nix`, `system/security.nix`, `system/ssh.nix`
   ```
   Para:
   ```
   - `system/networking.nix` — NetworkManager base (todos os hosts)
   - `system/networking-avahi.nix` — mDNS/Avahi (predator only)
   - `system/networking-resolved.nix` — systemd-resolved DNS (predator, cerebelo)
   - `system/networking-wireguard-client.nix` — WireGuard client com IPv6 toggle (predator only)
   - `system/networking-wireguard-server.nix` — WireGuard server com IP forwarding (aurelius only)
   - `system/security.nix` — firewall + SSH port + sudo policy
   - `system/ssh.nix` — OpenSSH daemon + client config
   ```

Validation:

- `./scripts/run-validation-gates.sh structure`
- `./scripts/check-docs-drift.sh` (continua passando — zero broken references)

Diff expectation:

- Apenas docs, zero mudança em eval/build.

Commit target:

- `docs: add missing feature files and expand networking glob in repo map`

### Phase 2: Extrair helper copy-once em waybar.nix

Targets:

- `modules/features/desktop/waybar.nix`

Changes:

Substituir 7 blocos inline por helper local + chamadas explícitas:

```nix
let
  mutableCopy = import ../../../lib/mutable-copy.nix { inherit lib; };
  provisionCopyOnce =
    { name, source, mode ? "0644" }:
    lib.hm.dag.entryAfter [ "writeBoundary" ] (
      mutableCopy.mkCopyOnce {
        inherit source mode;
        target = "$HOME/.config/waybar/${name}";
      }
    );
in
{
  home.activation = {
    provisionWaybarConfig          = provisionCopyOnce { name = "config";           source = ../../../config/apps/waybar/config; };
    provisionWaybarStyle           = provisionCopyOnce { name = "style.css";        source = ../../../config/apps/waybar/style.css; };
    provisionWaybarMakoScript      = provisionCopyOnce { name = "scripts/mako.sh";  source = ../../../config/apps/waybar/scripts/mako.sh;  mode = "0755"; };
    provisionWaybarMakoDndScript   = provisionCopyOnce { name = "scripts/mako-dnd.sh";  source = ../../../config/apps/waybar/scripts/mako-dnd.sh; mode = "0755"; };
    provisionWaybarMakoClearScript = provisionCopyOnce { name = "scripts/mako-clear.sh"; source = ../../../config/apps/waybar/scripts/mako-clear.sh; mode = "0755"; };
    provisionWaybarActiveWindowScript = provisionCopyOnce { name = "scripts/active-window.sh"; source = ../../../config/apps/waybar/scripts/active-window.sh; mode = "0755"; };
    provisionWaybarBottomConfig    = provisionCopyOnce { name = "bottom";           source = ../../../config/apps/waybar/bottom; };
  };
};
```

Redução: ~45 linhas (de 56 boilerplate para ~11 de helper + ~18 de chamadas).

Validation:

- `./scripts/run-validation-gates.sh structure`
- `nix eval path:$PWD#nixosConfigurations.predator.config.system.stateVersion`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`

Diff expectation:

- `nvd diff` mostra zero mudança nos closures. As strings das activations são
  idênticas — só a estrutura do código-fonte muda.

Commit target:

- `refactor(waybar): extract copy-once helper to reduce boilerplate`

### Phase 3: Extrair helper copy-once em walker.nix

Targets:

- `modules/features/desktop/walker.nix`

Changes:

Mesmo padrão — helper local com `name` derivando o target. Como os targets têm
prefixos diferentes (`walker/` vs `elephant/`), o helper aceita um `targetPrefix`:

```nix
let
  mutableCopy = import ../../../lib/mutable-copy.nix { inherit lib; };
  provisionCopyOnce =
    { name, source, targetPrefix, mode ? "0644" }:
    lib.hm.dag.entryAfter [ "writeBoundary" ] (
      mutableCopy.mkCopyOnce {
        inherit source mode;
        target = "$HOME/.config/${targetPrefix}/${name}";
      }
    );
in
{
  home.activation = {
    provisionWalkerConfig              = provisionCopyOnce { name = "config.toml";              source = ../../../config/apps/walker/config.toml;              targetPrefix = "walker"; };
    provisionElephantConfig            = provisionCopyOnce { name = "elephant.toml";             source = ../../../config/apps/elephant/elephant.toml;          targetPrefix = "elephant"; };
    provisionElephantClipboardConfig   = provisionCopyOnce { name = "clipboard.toml";            source = ../../../config/apps/elephant/clipboard.toml;         targetPrefix = "elephant"; };
    provisionElephantPowerMenu         = provisionCopyOnce { name = "menus/powermenu.toml";      source = ../../../config/apps/elephant/menus/powermenu.toml;   targetPrefix = "elephant"; };
    provisionElephantPowerMenuConfirmLogout   = provisionCopyOnce { name = "menus/powermenu-confirm-logout.toml";   source = ../../../config/apps/elephant/menus/powermenu-confirm-logout.toml;   targetPrefix = "elephant"; };
    provisionElephantPowerMenuConfirmReboot   = provisionCopyOnce { name = "menus/powermenu-confirm-reboot.toml";   source = ../../../config/apps/elephant/menus/powermenu-confirm-reboot.toml;   targetPrefix = "elephant"; };
    provisionElephantPowerMenuConfirmShutdown = provisionCopyOnce { name = "menus/powermenu-confirm-shutdown.toml"; source = ../../../config/apps/elephant/menus/powermenu-confirm-shutdown.toml; targetPrefix = "elephant"; };
  };
};
```

Redução: ~40 linhas.

Validation:

- Igual Phase 2.

Commit target:

- `refactor(walker): extract copy-once helper to reduce boilerplate`

## Risks

- **Baixo:** Refactor de copy-once é estruturalmente seguro — as strings
  resultantes das activations são idênticas. O `nvd diff` confirma zero
  mudança nos closures.
- **Baixo:** Mudanças no repo map são só documentação — zero impacto em
  eval/build.

## Definition of Done

- [ ] `docs/for-agents/001-repo-map.md` lista todos os 74 feature files sem globs.
- [ ] `waybar.nix` usa helper local para copy-once.
- [ ] `walker.nix` usa helper local para copy-once.
- [ ] `./scripts/run-validation-gates.sh structure` passa.
- [ ] `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel` passa.
- [ ] `nvd diff` mostra zero mudança nos closures de predator.
