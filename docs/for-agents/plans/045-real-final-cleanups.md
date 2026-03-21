# Real Final Cleanups

## Goal

Resolver os últimos problemas reais que sobraram depois do alinhamento ao
`dendritic`, sem criar framework novo nem esconder composição.

## Scope

In scope:
- `scripts/check-desktop-composition-matrix.sh`
- `modules/desktops/dms-on-niri.nix`
- `modules/desktops/niri-standalone.nix`
- `modules/users/higorprado.nix`
- `hardware/predator/_persistence-inventory.nix`
- consumidores diretos do arquivo de persistência

Out of scope:
- `flake.lock`
- mudanças de comportamento das configurações
- refactors só cosméticos
- novas surfaces de option/contract/helper genérico

## Confirmed Problems

1. `check-desktop-composition-matrix.sh` declara expectativa para `greeter`,
   mas hoje só valida `standalone`.
2. `dms-on-niri.nix` e `niri-standalone.nix` duplicam o mesmo bloco de HM para
   overrides de portal; só variam no `custom.kdl` e no valor de
   `custom.niri.standaloneSession`.
3. `modules/users/higorprado.nix` ainda tem aliases locais que não compram
   muito:
   - `primaryGroup = userName`
   - `primaryUserGroups` + `extraGroups` com o mesmo valor
4. `hardware/predator/_persistence-inventory.nix` tem conteúdo legítimo, mas o
   nome ainda carrega o vocabulário ruim de “inventory”.

## Desired End State

- desktop matrix valida tudo o que diz validar
- os dois composition files de desktop compartilham só a duplicação real, sem
  criar helper/framework novo
- `higorprado.nix` fica um pouco mais direto sem perder legibilidade
- o arquivo de persistência do `predator` ganha um nome honesto e os
  consumidores acompanham

## Phases

### Phase 0: Baseline

Validation:
- `sed -n '1,220p' scripts/check-desktop-composition-matrix.sh`
- `sed -n '1,220p' modules/desktops/dms-on-niri.nix`
- `sed -n '1,220p' modules/desktops/niri-standalone.nix`
- `sed -n '1,200p' modules/users/higorprado.nix`
- `sed -n '1,220p' hardware/predator/_persistence-inventory.nix`
- `rg -n '_persistence-inventory' .`

### Phase 1: Fix the Real Test Gap

Changes:
- fazer `check-desktop-composition-matrix.sh` validar também o `greeter`
  prometido pelo próprio `expected_feature_json`

Validation:
- `./scripts/check-desktop-composition-matrix.sh`
- `./scripts/run-validation-gates.sh structure`

### Phase 2: Remove Honest Duplication in Desktop Compositions

Change rule:
- só extrair o bloco HM compartilhado se isso reduzir duplicação sem criar um
  helper abstrato ou esconder o que cada composition muda

Likely shape:
- manter cada composition explícita
- extrair no máximo um binding local com o bloco HM comum

Validation:
- `./scripts/check-desktop-composition-matrix.sh`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`

### Phase 3: Tighten the Tracked User Owner

Changes:
- remover aliases locais redundantes em `modules/users/higorprado.nix` se isso
  realmente reduzir ruído

Validation:
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`

### Phase 4: Rename the Persistence File Honestly

Changes:
- renomear `_persistence-inventory.nix` para um nome melhor
- ajustar `impermanence.nix`, scripts e docs que apontarem para ele

Validation:
- `bash tests/scripts/report-persistence-candidates-test.sh`
- `./scripts/check-docs-drift.sh`
- `./scripts/run-validation-gates.sh all`

## Definition of Done

- desktop matrix valida `standalone` e `greeter`
- composições desktop não repetem o mesmo bloco HM à toa
- `higorprado.nix` fica mais direto sem perder clareza
- o arquivo de paths persistidos do `predator` tem nome honesto
