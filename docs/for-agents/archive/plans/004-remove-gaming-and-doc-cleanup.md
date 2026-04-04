# Remove Gaming Module and Doc Cleanup

## Goal

Remover o módulo de gaming do predator, manter os validation gates passando,
e deixar a documentação consistente com o estado real do repo.

## Scope

In scope:
- Remover `nixos.gaming` e `homeManager.gaming` do predator.nix (ambas as
  variantes de desktop)
- Deletar `modules/features/desktop/gaming.nix`
- Arquivar plan 002 (cyberpunk gaming fix — concluído)
- Atualizar status de plan 003 (home migration — Phase 3 concluída)
- Validation gates passando após as mudanças

Out of scope:
- Remover outros pacotes de jogos instalados manualmente fora do módulo
- Alterar flatpak.nix ou qualquer outro módulo de desktop
- Merge para main (decisão separada do usuário)

## Current State

- `modules/features/desktop/gaming.nix` — declara `flake.modules.nixos.gaming`
  e `flake.modules.homeManager.gaming`
- `modules/hosts/predator.nix` — referencia `nixos.gaming` em
  `nixosDesktopNiri` (linha 92) e `nixosDesktopNoctalia` (linha 106);
  `homeManager.gaming` em `hmDesktopNiri` (linha 150) e
  `hmDesktopNoctalia` (linha 167)
- Validation gates: passando
- Plan 002: todas as fases concluídas, ainda em `plans/` (deveria estar em archive)
- Plan 003: Phase 3 concluída, Phase 4 ainda pendente (boot sem disco de 2TB)

## Desired End State

- Nenhuma referência a `gaming` em predator.nix
- `modules/features/desktop/gaming.nix` deletado
- Plan 002 arquivado em `docs/for-agents/archive/plans/`
- Plan 003 com status atualizado
- `./scripts/run-validation-gates.sh` → ok
- `nix eval .#nixosConfigurations.predator.config.system.build.toplevel.drvPath` → ok

## Phases

### Phase 0: Baseline

Validation:
- `./scripts/run-validation-gates.sh` → ok (já confirmado)

### Phase 1: Remover gaming do predator

Targets:
- `modules/hosts/predator.nix` — remover 4 referências
- `modules/features/desktop/gaming.nix` — deletar

Changes em predator.nix:
- `nixosDesktopNiri`: remover `nixos.gaming`
- `nixosDesktopNoctalia`: remover `nixos.gaming`
- `hmDesktopNiri`: remover `homeManager.gaming`
- `hmDesktopNoctalia`: remover `homeManager.gaming`

Validation:
- `nix eval .#nixosConfigurations.predator.config.system.build.toplevel.drvPath`
- `./scripts/run-validation-gates.sh`

Diff expectation:
- predator.nix: 4 linhas removidas
- gaming.nix: arquivo deletado

Commit target:
- `feat(predator): remove gaming module`

### Phase 2: Doc cleanup

Changes:
- Mover `docs/for-agents/plans/002-cyberpunk-gaming-fix.md` para
  `docs/for-agents/archive/plans/002-cyberpunk-gaming-fix.md`
- Atualizar `docs/for-agents/plans/003-home-migration-windows-dualboot.md`:
  marcar Phases 0–3 como concluídas, Phase 4 como pendente

Commit target:
- `docs: archive plan 002, update plan 003 status`

## Definition of Done

- `grep -r "gaming" modules/hosts/predator.nix` → sem resultado
- `modules/features/desktop/gaming.nix` não existe
- `docs/for-agents/archive/plans/002-cyberpunk-gaming-fix.md` existe
- `docs/for-agents/plans/002-cyberpunk-gaming-fix.md` não existe
- Validation gates passando
