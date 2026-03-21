# Final Runtime Polish

## Goal

Fechar os últimos restos pequenos depois da migração para o shape dendritic,
sem criar abstração nova nem mexer no runtime por estética vazia.

## Scope

In scope:
- `modules/users/higorprado.nix`
- `scripts/check-desktop-composition-matrix.sh`
- `scripts/check-extension-contracts.sh`
- `scripts/check-feature-legacy-role-conditionals.sh`
- arquivamento de `040-final-structural-cleanups.md`
- arquivamento de `041-hardware-boundary-cleanup.md`

Out of scope:
- `flake.lock`
- qualquer mudança de comportamento das configurações
- qualquer refactor em features sem ganho material

## Confirmed Problems

1. `username` ainda usa `lib.types.str`, mais frouxo do que a referência.
2. `check-desktop-composition-matrix.sh` ainda hardcodeia o usuário real do
   repo em vez de derivá-lo uma vez do runtime.
3. `check-extension-contracts.sh` ainda carrega resíduo feio de migração no
   próprio código do script.
4. `check-feature-legacy-role-conditionals.sh` ainda usa `grep` cru e ficou
   abaixo do padrão atual dos outros checks.
5. Os planos `040` e `041` continuam largados em `plans/` mesmo depois de
   fechados.

## Desired End State

- `username` fica com tipo estreito (`singleLineStr`)
- o desktop matrix deriva o username do runtime real do repo
- extension contracts perde resíduo de string concatenada e paths legados
- o guardrail de role legado usa `rg` e fica legível
- `040` e `041` saem de `plans/` e vão para `archive/plans/`

## Phases

### Phase 0: Baseline

Validation:
- `sed -n '1,120p' modules/users/higorprado.nix`
- `sed -n '1,220p' scripts/check-desktop-composition-matrix.sh`
- `sed -n '1,180p' scripts/check-extension-contracts.sh`
- `sed -n '1,120p' scripts/check-feature-legacy-role-conditionals.sh`

### Phase 1: Tighten Runtime Facts

Changes:
- trocar `lib.types.str` por `lib.types.singleLineStr` em `username`
- desktop matrix passa a derivar o `username` real via `nix eval` uma vez

Validation:
- `./scripts/check-desktop-composition-matrix.sh`
- `bash -lc 'source scripts/lib/nix_eval.sh; nix_eval_sole_hm_user_for_host predator'`

### Phase 2: Tooling Cleanup

Changes:
- simplificar variáveis legadas em `check-extension-contracts.sh`
- trocar `grep` por `rg` em `check-feature-legacy-role-conditionals.sh`

Validation:
- `./scripts/check-extension-contracts.sh`
- `./scripts/run-validation-gates.sh structure`

### Phase 3: Archive Dead Plan Noise

Changes:
- mover `040-final-structural-cleanups.md` para `archive/plans/`
- mover `041-hardware-boundary-cleanup.md` para `archive/plans/`

Validation:
- `./scripts/check-docs-drift.sh`
- `./scripts/run-validation-gates.sh all`

## Definition of Done

- `username` usa contrato estreito
- desktop matrix não hardcodeia mais o usuário real do repo
- os dois scripts de tooling ficam sem resto feio desnecessário
- `040` e `041` deixam de poluir `plans/`
