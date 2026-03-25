# CI: Remove Stale niri.standaloneSession Contract

## Goal

Corrigir a falha diária do CI causada por um contrato obsoleto em
`scripts/check-config-contracts.sh` que referencia um atributo Nix removido.

## Scope

In scope:
- remover o check `predator niri standalone session` de `check-config-contracts.sh`

Out of scope:
- alterar qualquer outra parte do CI
- reintroduzir a opção `custom.niri.standaloneSession`
- simplificações estruturais do workflow

## Current State

- Commit `0e708b2` ("refactor(runtime): remove non-dendritic option surfaces") removeu a
  opção `custom.niri.standaloneSession` do flake.
- `check-config-contracts.sh` ainda faz:
  ```bash
  expect_equal "predator niri standalone session" \
    "$(bool_eval "path:$PWD#nixosConfigurations.predator.config.custom.niri.standaloneSession")" \
    "false"
  ```
- `nix eval` falha com "does not provide attribute" → o check registra `got ''` → CI falha.
- O CI scheduled (weekdays 12:00 UTC) falha desde `0e708b2` (2026-03-20).
- As invariantes cobertas pelo contrato removido já estão cobertas pelos checks existentes:
  - `predator niri feature` → verifica que niri está composto
  - `predator dms feature` → verifica que DMS está composto
  - composição niri + DMS = dms-on-niri, não standalone

## Desired End State

- A linha do `standaloneSession` removida de `check-config-contracts.sh`
- `./scripts/run-validation-gates.sh predator` passa localmente
- CI scheduled passa

## Phases

### Phase 0: Baseline

Validation:
- `./scripts/check-config-contracts.sh 2>&1 | grep standaloneSession`
  — deve mostrar a falha

### Phase 1: Remover contrato obsoleto

Arquivo: `scripts/check-config-contracts.sh`

Changes:
- Remover a linha:
  ```bash
  expect_equal "predator niri standalone session" "$(bool_eval "path:$PWD#nixosConfigurations.predator.config.custom.niri.standaloneSession")" "false"
  ```

Validation:
- `./scripts/check-config-contracts.sh` — deve terminar com `[config-contracts] ok`
- `./scripts/run-validation-gates.sh structure` — sem erros

Commit target:
- `fix(ci): remove stale custom.niri.standaloneSession contract`

## Risks

- Nenhum: a invariante era redundante com os checks existentes de niri + dms feature.

## Definition of Done

- `check-config-contracts.sh` sem referência a `standaloneSession`
- Gates locais passam
