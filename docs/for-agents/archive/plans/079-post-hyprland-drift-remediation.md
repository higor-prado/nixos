# Post-Hyprland Drift Remediation Plan

## Goal

Eliminar drift entre código/documentação/padrões do repositório após a migração para Hyprland, mantendo conformidade com as regras dendríticas, boundaries de ownership e convenções de documentação operacional do repo.

## Scope

In scope:
- Alinhamento de documentação viva com o estado real do runtime atual.
- Correção de inconsistências introduzidas/acentuadas após os commits da migração Hyprland.
- Higiene de localização de planos/notas operacionais conforme `docs/for-agents/*`.
- Verificação de conformidade estrutural pós-ajustes.

Out of scope:
- Refatoração funcional da stack desktop (Niri/Hyprland/Noctalia).
- Mudanças em overrides privados.
- Mudanças de comportamento runtime não necessárias para corrigir drift documental/processual.

## Current State

- `./scripts/run-validation-gates.sh structure` passa integralmente.
- Desktop ativo em `modules/hosts/predator.nix` é Hyprland (`desktop-hyprland-standalone` + módulos Hyprland HM/NixOS).
- Drifts documentais vivos identificados:
  - `docs/for-agents/001-repo-map.md` com contagens/superfície de desktop desatualizadas.
  - `docs/for-humans/00-start-here.md` com descrição de predator ainda em Niri e inventário de hosts incompleto.
  - `docs/for-humans/03-multi-host.md` com seção predator ainda em Niri + DMS.
  - `docs/for-humans/02-structure.md` com contagens rígidas e lista de `config/` incompleta.
  - `README.md` com exemplo de composição desktop enfatizando `desktop-dms-on-niri` como referência principal.
- Drift de processo documental:
  - arquivos de plano/nota em `local/`:
    - `local/PLAN.md`
    - `local/HYPRLAND_UWSM_FIX.md`
  - isso conflita com a regra de manter docs ativos em `docs/for-agents/plans/` e `docs/for-agents/current/`.

## Desired End State

- Documentação viva (`README.md`, `docs/for-humans/*`, `docs/for-agents/001-repo-map.md`) consistente com o runtime atual.
- Nenhum artefato ativo de plano/nota operacional fora das pastas canônicas de docs de agente.
- Validação estrutural permanece verde após as correções.

## Phases

### Phase 0: Baseline

Validation:
- `./scripts/run-validation-gates.sh structure`
- `git status --short`
- `rg -n "Niri|dms-on-niri|modules/desktops/   2|modules/features/   72" README.md docs/for-humans docs/for-agents/001-repo-map.md`

Diff expectation:
- sem diff (baseline apenas)

Commit target:
- nenhum

### Phase 1: Corrigir mapa canônico de agentes

Targets:
- `docs/for-agents/001-repo-map.md`

Changes:
- Atualizar contagens e/ou remover números hardcoded frágeis.
- Atualizar seção `modules/desktops/` para incluir as composições atuais.
- Ajustar descrições para refletir stack Hyprland vigente no predator sem apagar alternativas existentes.

Validation:
- `./scripts/check-docs-drift.sh`
- `./scripts/check-desktop-composition-matrix.sh`
- `./scripts/run-validation-gates.sh structure`

Diff expectation:
- apenas docs de agente; sem alteração de runtime Nix

Commit target:
- `docs(agents): sync repo-map with post-hyprland desktop surface`

### Phase 2: Corrigir docs humanas + README

Targets:
- `README.md`
- `docs/for-humans/00-start-here.md`
- `docs/for-humans/02-structure.md`
- `docs/for-humans/03-multi-host.md`

Changes:
- Atualizar descrição do predator para Hyprland (mantendo Niri/Noctalia como alternativas quando relevante).
- Atualizar inventário de hosts (predator, aurelius, cerebelo).
- Corrigir exemplos de composição desktop para não induzir Niri como baseline atual.
- Reduzir fragilidade de contagens rígidas onde aplicável.

Validation:
- `./scripts/check-docs-drift.sh`
- `./scripts/run-validation-gates.sh structure`

Diff expectation:
- apenas documentação (`README.md` + docs humanas)

Commit target:
- `docs(humans): align host and desktop docs with current hyprland runtime`

### Phase 3: Higiene de localização de planos/notas operacionais

Targets:
- `local/PLAN.md`
- `local/HYPRLAND_UWSM_FIX.md`
- destino em `docs/for-agents/plans/`, `docs/for-agents/current/` ou `docs/for-agents/archive/reports/`

Changes:
- Classificar cada arquivo (`ativo`, `histórico`, `obsoleto`).
- Migrar para superfície canônica:
  - ativo -> `plans/` e/ou `current/`
  - histórico -> `archive/reports/` (ou `archive/log-tracks/` quando for trilha de execução)
  - obsoleto -> remover

Validation:
- `./scripts/check-docs-drift.sh`
- `./scripts/run-validation-gates.sh structure`
- `find docs/for-agents/{plans,current} -maxdepth 1 -type f | sort`

Diff expectation:
- movimentação/renomeação de docs; sem mudança funcional de módulos

Commit target:
- `chore(docs): enforce agent plan/log location contracts`

### Phase 4: Fechamento e não-regressão

Validation:
- `./scripts/run-validation-gates.sh all` (preferencial)
- mínimo: `./scripts/run-validation-gates.sh structure`

Diff expectation:
- zero mudanças adicionais

Commit target:
- nenhum

## Risks

- Correções parciais em docs podem gerar novo drift semântico.
- Movimentação de arquivos em `local/` sem classificação correta pode perder contexto operacional útil.
- Reintrodução de contagens rígidas aumenta chance de drift recorrente.

## Definition of Done

- `docs/for-agents/001-repo-map.md` consistente com a árvore real.
- `README.md` e `docs/for-humans/*` refletem host/desktop atuais.
- Nenhum plano/nota operacional ativo fora da superfície canônica sem justificativa explícita.
- `./scripts/run-validation-gates.sh structure` verde após as mudanças.
- preferencialmente `./scripts/run-validation-gates.sh all` verde no fechamento.
