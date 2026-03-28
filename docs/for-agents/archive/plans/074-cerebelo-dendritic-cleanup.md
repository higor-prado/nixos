# Cerebelo Dendritic Conformance Cleanup

## Goal

Alinhar o host cerebelo ao padrão dendritic do repositório: mover a config de
board para `hardware/cerebelo/`, reestruturar o host module com grupos nomeados,
adicionar Tailscale e attic modules, configurar abreviações `ncb*` no predator e
no próprio cerebelo, expandir cobertura de validação e arquivar a documentação
de deploy concluída (plans 072/073).

## Scope

In scope:
- Mover `modules/features/system/rk3588-orangepi5.nix` → `hardware/cerebelo/board.nix`
- Reestruturar `modules/hosts/cerebelo.nix` com grupos nomeados
- `nixos.tailscale` em cerebelo
- Abreviações `ncb*` em cerebelo (self) e predator (remote deploy)
- `nixos.attic-publisher` + `nixos.attic-client` em cerebelo
- Atualizar `.example` do cerebelo com shape do attic config
- Expandir `run_cerebelo_gates` com contracts + HM stateVersion eval
- Arquivar plans 072/073 e progress log 072; atualizar 001-repo-map.md

Out of scope:
- Build completo do system toplevel no CI (aarch64 cross-compile)
- Configuração operacional do attic token pós-deploy
- `tailscale up` no cerebelo (operacional, pós-deploy)

## Outcome

Completed. Branch `cerebelo`, commits `68b9460` → `7b674df` (após rewrite de
histórico via `git filter-repo` para remover valores reais de templates).

## Definition of Done

- `./scripts/run-validation-gates.sh all` passa sem erros ✓
- `modules/features/system/rk3588-orangepi5.nix` não existe ✓
- `hardware/cerebelo/board.nix` existe com boot loader + overlays ✓
- `modules/hosts/cerebelo.nix` usa grupos nomeados ✓
- `modules/hosts/predator.nix` contém grupo `ncb*` em operatorFishAbbrs ✓
- `private/hosts/cerebelo/default.nix.example` contém shape do attic config (só placeholders) ✓
- `run_cerebelo_gates` inclui `check-config-contracts.sh` + HM stateVersion eval ✓
- Plans 072/073 e progress log 072 em `archive/` ✓
- `hardware/cerebelo/` documentado em 001-repo-map.md ✓
