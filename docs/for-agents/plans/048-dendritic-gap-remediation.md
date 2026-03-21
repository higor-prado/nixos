# Dendritic Gap Remediation

## Goal

Fechar os gaps identificados na auditoria do repo: remover o único arquivo não-módulo
dentro da árvore import-tree, eliminar duplicação entre composições de desktop, e
normalizar inconsistências menores de escopo entre hosts.

## Scope

In scope:
- Mover `modules/features/shell/_starship-settings.nix` para `lib/`
- Extrair o bloco homeManager duplicado entre `dms-on-niri.nix` e `niri-standalone.nix`
- Normalizar camada dos fish abbrs de operador no `aurelius.nix` (HM em vez de NixOS)
- Mover `sharedModules = [ catppuccin ]` de `home-manager-settings.nix` para escopo desktop

Out of scope:
- Qualquer mudança funcional nos hosts — nenhuma opção NixOS deve mudar de valor (exceto Phase 3 onde a mudança é intencional e de escopo de camada)
- Novos features, novos hosts, qualquer coisa além dos gaps listados

## Current State

- `modules/features/shell/_starship-settings.nix` — attrset puro dentro da árvore import-tree; o prefixo `_` instrui o import-tree a pular o arquivo, mas ele quebra o invariante "todo arquivo na árvore é um módulo"
- `modules/desktops/dms-on-niri.nix` e `modules/desktops/niri-standalone.nix` — blocos `homeManager` com dois `xdg.configFile` idênticos (override de PATH dos portal services) e `mutableCopy.mkCopyOnce` com paths de KDL diferentes
- `modules/hosts/aurelius.nix` linha 51 — `programs.fish.shellAbbrs` no nível NixOS; `predator.nix` usa `home-manager.users.${userName}` para o mesmo propósito
- `modules/features/core/home-manager-settings.nix` linha 9 — `sharedModules = [ inputs.catppuccin.homeModules.catppuccin ]` aplicado globalmente, inclusive no aurelius (servidor, sem desktop)

## Desired End State

- `lib/starship-settings.nix` existe; `modules/features/shell/_starship-settings.nix` removido
- `starship.nix` importa de `../../../lib/starship-settings.nix`
- Os dois arquivos de composição de desktop sem bloco `xdg.configFile` duplicado; helper em `lib/`
- `aurelius.nix` com os abbrs de operador dentro de `home-manager.users.${userName}`
- `home-manager-settings.nix` sem o `sharedModules` catppuccin; catppuccin HM module adicionado nas composições de desktop que o usam

## Phases

### Phase 0: Baseline

Validation:
- `nix eval .#nixosConfigurations.predator.config.system.build.toplevel.drvPath`
- `nix eval .#nixosConfigurations.aurelius.config.system.build.toplevel.drvPath`
- `./scripts/run-validation-gates.sh structure`

### Phase 1: Mover `_starship-settings.nix` para `lib/`

Targets:
- `modules/features/shell/_starship-settings.nix` → deletar
- `lib/starship-settings.nix` → criar com conteúdo idêntico
- `modules/features/shell/starship.nix` → atualizar import path

Changes:
- Criar `lib/starship-settings.nix` com o conteúdo atual de `_starship-settings.nix`
- Em `starship.nix`, trocar `import ./_starship-settings.nix` por `import ../../../lib/starship-settings.nix`
- Deletar `modules/features/shell/_starship-settings.nix`

Validation:
- `nix eval .#nixosConfigurations.predator.config.system.build.toplevel.drvPath`
- `./scripts/run-validation-gates.sh structure`

Diff expectation:
- Nenhuma mudança de derivação

Commit target:
- `refactor(shell): move starship settings data file out of module tree into lib/`

### Phase 2: Eliminar duplicação nos desktop compositions

Targets:
- `modules/desktops/dms-on-niri.nix`
- `modules/desktops/niri-standalone.nix`
- `lib/wayland-portal-path.nix` (novo)

Changes:
- Criar `lib/wayland-portal-path.nix` com uma função `mkPortalPathOverrides` que retorna os dois `xdg.configFile` de override de PATH dos portal services
- Nos dois arquivos de composição, substituir o bloco inline duplicado pela chamada ao helper
- O `mutableCopy.mkCopyOnce` permanece em cada arquivo individualmente (paths de KDL distintos)

Validation:
- `nix eval .#nixosConfigurations.predator.config.system.build.toplevel.drvPath`
- `./scripts/run-validation-gates.sh structure`

Diff expectation:
- Nenhuma mudança de derivação

Commit target:
- `refactor(desktop): extract duplicated portal PATH override into lib helper`

### Phase 3: Normalizar fish abbrs de operador no aurelius

Targets:
- `modules/hosts/aurelius.nix`

Changes:
- Mover o bloco `programs.fish.shellAbbrs { naui ... }` do nível NixOS para dentro de `home-manager.users.${userName}` como `programs.fish.shellAbbrs`

Validation:
- `nix eval .#nixosConfigurations.aurelius.config.system.build.toplevel.drvPath`
- Confirmar que os abbrs aparecem em `config.home-manager.users.higorprado.programs.fish.shellAbbrs` e não em `config.programs.fish.shellAbbrs`

Diff expectation:
- Mudança de derivação esperada: abbrs saem de `/etc/fish/conf.d/` e vão para o perfil HM do usuário

Commit target:
- `refactor(aurelius): move operator fish abbrs to home-manager scope`

### Phase 4: Mover catppuccin HM module para escopo desktop [BLOQUEADA]

**Motivo do bloqueio:** features como `homeManager.fish` e `homeManager.starship` setam opções
`catppuccin.*` (e.g., `catppuccin.fish.enable = true`). Essas opções só existem quando o
catppuccin HM module está disponível via `sharedModules`. Mover o `sharedModules` para escopo
desktop quebra `aurelius` porque ele importa `homeManager.fish`. A pré-condição para executar
esta phase é separar a config catppuccin das features usadas no servidor — e.g., extrair
`catppuccin.fish.enable` de `fish.nix` para um módulo desktop-exclusivo. Isso está fora do
escopo deste plano.

### Phase 4 original (não executável agora): Mover catppuccin HM module para escopo desktop

Targets:
- `modules/features/core/home-manager-settings.nix`
- `modules/desktops/dms-on-niri.nix`
- `modules/desktops/niri-standalone.nix`

Changes:
- Remover `sharedModules = [ inputs.catppuccin.homeModules.catppuccin ]` de `home-manager-settings.nix`
- Adicionar `home-manager.sharedModules = [ inputs.catppuccin.homeModules.catppuccin ]` no bloco NixOS de `dms-on-niri.nix` e `niri-standalone.nix`

Validation:
- `nix eval .#nixosConfigurations.predator.config.system.build.toplevel.drvPath`
- `nix eval .#nixosConfigurations.aurelius.config.system.build.toplevel.drvPath`
- Confirmar que aurelius não avalia mais o catppuccin HM module

Diff expectation:
- predator: sem mudança funcional (catppuccin HM ainda presente via composição de desktop)
- aurelius: remoção do catppuccin HM module da avaliação

Commit target:
- `refactor(desktop): scope catppuccin HM module to desktop compositions only`

## Risks

- Phase 3: a mudança de NixOS → HM para os abbrs do aurelius é intencional e produz diff de derivação. aurelius tem só um usuário HM, então o resultado visível é o mesmo.
- Phase 4: `sharedModules` no HM integration do NixOS aplica o módulo a todos os usuários HM do host. Remover de `home-manager-settings.nix` e re-adicionar nas composições de desktop deve cobrir todos os casos. Confirmar antes que não existe host sem composição de desktop que dependa do catppuccin HM module.

## Definition of Done

- `modules/features/shell/_starship-settings.nix` não existe
- `lib/starship-settings.nix` existe
- `dms-on-niri.nix` e `niri-standalone.nix` sem blocos `xdg.configFile` duplicados
- `aurelius.nix` sem `programs.fish.shellAbbrs` no nível NixOS
- `home-manager-settings.nix` sem `sharedModules`
- Todos os gates passam
- Quatro commits, um por phase
