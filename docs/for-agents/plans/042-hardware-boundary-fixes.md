# Hardware Boundary Fixes

## Goal

Corrigir os erros de ownership em `hardware/` que continuam claramente errados,
sem abrir refactor especulativo em áreas que ainda são defensáveis.

## Confirmed Problems

### 1. `hardware/predator/overlays.nix`

Problema:
- o arquivo carrega patch/workaround de pacote (`nixpkgs.overlays`)
- isso não descreve hardware, boot, disco, criptografia, persistência ou
  quirk de device concreto

Conclusão:
- não deve ficar em `hardware/`

### 2. `hardware/aurelius/default.nix`

Problema:
- o arquivo mistura imports legítimos de hardware com `system.stateVersion`
- `system.stateVersion` é runtime policy do host, não hardware

Conclusão:
- `system.stateVersion` deve sair de `hardware/aurelius/default.nix`

## Explicit Non-Goals

Os itens abaixo **não** entram neste plano porque a classificação deles ainda é
discutível e hoje pode ser defendida com base no hardware concreto:

- `hardware/predator/packages.nix`
- `hardware/predator/performance.nix`
- `hardware/aurelius/performance.nix`

## Desired End State

- `hardware/` não contém patch/workaround de pacote
- `hardware/aurelius/default.nix` volta a ser hardware/boot/disko only
- o restante de `hardware/` fica intacto
- nenhuma abstração ou bucket novo é criado só para mover sujeira

## Refactor Direction

### Phase 0: Baseline

Targets:
- `hardware/predator/overlays.nix`
- `hardware/predator/default.nix`
- `hardware/aurelius/default.nix`
- `modules/hosts/predator.nix`
- `modules/hosts/aurelius.nix`

Validation:
- `sed -n '1,200p' hardware/predator/overlays.nix`
- `sed -n '1,200p' hardware/predator/default.nix`
- `sed -n '1,200p' hardware/aurelius/default.nix`
- `sed -n '1,220p' modules/hosts/predator.nix`
- `sed -n '1,220p' modules/hosts/aurelius.nix`

### Phase 1: Move predator overlay ownership out of `hardware/`

Targets:
- `hardware/predator/overlays.nix`
- `hardware/predator/default.nix`
- `modules/hosts/predator.nix`

Changes:
- mover o conteúdo de `hardware/predator/overlays.nix` para um owner
  host-specific fora de `hardware/`
- preferir um nome explícito adjacente ao host, por exemplo
  `modules/hosts/predator-nixpkgs-overlays.nix`
- ajustar o wiring para o `predator` continuar importando isso de forma
  explícita
- remover `./overlays.nix` de `hardware/predator/default.nix`

Non-goals:
- não criar bucket genérico novo
- não promover para `pkgs/` a menos que o override passe a ser realmente
  compartilhado

### Phase 2: Move `system.stateVersion` out of aurelius hardware default

Targets:
- `hardware/aurelius/default.nix`
- `modules/hosts/aurelius.nix`

Changes:
- remover `system.stateVersion` de `hardware/aurelius/default.nix`
- materializar `system.stateVersion` no owner correto do host `aurelius`

### Phase 3: Tighten docs

Targets:
- `docs/for-agents/000-operating-rules.md`
- `docs/for-agents/001-repo-map.md`
- `docs/for-agents/003-module-ownership.md`
- `docs/for-humans/02-structure.md`

Changes:
- parar de listar `overlays` como parte natural de `hardware/<host>/`
- documentar que patch/workaround de pacote host-specific fica no owner do host,
  não em `hardware/`

## Validation

After each meaningful slice:
- `./scripts/run-validation-gates.sh structure`
- `nix flake metadata path:$PWD`
- `nix eval --raw path:$PWD#nixosConfigurations.predator.config.system.stateVersion`
- `nix eval --raw path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.stateVersion`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`

Final:
- `./scripts/run-validation-gates.sh all`
- `./scripts/check-docs-drift.sh`

## Definition of Done

- `hardware/predator/overlays.nix` não existe mais em `hardware/`
- `system.stateVersion` não existe mais em `hardware/aurelius/default.nix`
- `hardware/` só conserva os casos realmente defensáveis
- nenhum refactor especulativo foi acoplado a esse corte
