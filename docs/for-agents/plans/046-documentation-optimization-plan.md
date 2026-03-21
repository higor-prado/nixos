# Documentation Optimization Plan

## Goal

Otimizar a documentação inteira do repo para que ela fique:

- menor na superfície ativa
- mais fácil de navegar
- mais coerente com o runtime real
- mais clara sobre o que é estado atual vs histórico

Sem overengineering:
- sem criar sistema de docs novo
- sem duplicar conteúdo só para “organizar melhor”
- sem reescrever textos que já estejam corretos e úteis

## Why This Matters

Hoje o problema principal da documentação não é falta de informação. É:

1. **superfície ativa grande demais**
   - muitos planos e logs ainda vivem fora do archive
   - isso aumenta ruído para agentes e humanos

2. **redundância entre camadas**
   - `README.md`
   - `docs/README.md`
   - `docs/for-humans/*.md`
   - `docs/for-agents/*.md`
   dizem partes parecidas com framing diferente

3. **terminologia ainda irregular**
   - ainda aparece vocabulário herdado em alguns lugares
   - parte dos docs usa termos mais honestos do que outros
   - o mesmo vale para nomes antigos vs nomes atuais como `persisted paths`

4. **histórico misturado com guidance vivo**
   - `plans/` e `current/` ainda carregam muita história de migração
   - parte disso é útil como auditoria, mas não precisa competir com a
     documentação operacional viva

5. **fronteiras entre públicos ainda podem melhorar**
   - docs para humanos às vezes repetem detalhe muito interno
   - docs para agentes às vezes assumem contexto histórico demais

## Current Documentation Surface

### Living agent docs

- `docs/for-agents/000-operating-rules.md`
- `docs/for-agents/001-repo-map.md`
- `docs/for-agents/002-architecture.md`
- `docs/for-agents/003-module-ownership.md`
- `docs/for-agents/004-private-safety.md`
- `docs/for-agents/005-validation-gates.md`
- `docs/for-agents/006-extensibility.md`
- `docs/for-agents/007-option-migrations.md`
- `docs/for-agents/999-lessons-learned.md`

### Living human docs

- `docs/for-humans/00-start-here.md`
- `docs/for-humans/01-philosophy.md`
- `docs/for-humans/02-structure.md`
- `docs/for-humans/03-multi-host.md`
- `docs/for-humans/04-private-overrides.md`
- `docs/for-humans/05-dev-environment.md`
- `docs/for-humans/workflows/*.md`

### Active execution docs that now deserve scrutiny

`docs/for-agents/plans/` still contains:
- `033-organization-hardening-plan.md`
- `034-host-runtime-cleanup-plan.md`
- `035-remove-non-dendritic-option-surfaces.md`
- `036-test-harness-cleanup.md`
- `037-structural-dendritic-alignment.md`
- `038-remove-script-side-host-descriptors.md`
- `039-remove-user-import-special-case.md`
- `042-hardware-boundary-fixes.md`
- `043-post-dendritic-audit-cleanups.md`
- `044-final-runtime-polish.md`
- `045-real-final-cleanups.md`

`docs/for-agents/current/` still contains the corresponding progress logs.

A maior parte disso já é histórico de migração concluída, não guidance ativo.

## Optimization Principles

1. **Keep living docs small**
   - o que não serve para operar o repo hoje deve sair da superfície viva

2. **One document, one job**
   - `001-repo-map.md` mapeia
   - `002-architecture.md` explica o runtime
   - `003-module-ownership.md` fixa fronteiras
   - `005-validation-gates.md` fala só de validação
   - evitar duplicar a mesma explicação nos quatro

3. **History belongs in archive**
   - planos/logs concluídos devem ir para `archive/`
   - docs vivos só citam histórico quando isso ainda ajuda decisão presente

4. **Human docs optimize for use**
   - menos teoria repetida
   - mais “onde mexer”, “como usar”, “o que é seguro”

5. **Agent docs optimize for correctness**
   - menos narrativa
   - mais contrato operacional

6. **Terminology must be explicit and stable**
   - usar uma palavra por conceito
   - exemplo:
     - `host owner file`
     - `concrete host configuration`
     - `persisted paths`
     - `shared script registry`

## Confirmed Improvement Areas

### A. Archive completed migration docs

The active surface is still too noisy.

Strong candidates to archive now:
- `docs/for-agents/plans/033-organization-hardening-plan.md`
- `docs/for-agents/plans/034-host-runtime-cleanup-plan.md`
- `docs/for-agents/plans/035-remove-non-dendritic-option-surfaces.md`
- `docs/for-agents/plans/036-test-harness-cleanup.md`
- `docs/for-agents/plans/037-structural-dendritic-alignment.md`
- `docs/for-agents/plans/038-remove-script-side-host-descriptors.md`
- `docs/for-agents/plans/039-remove-user-import-special-case.md`
- `docs/for-agents/plans/042-hardware-boundary-fixes.md`
- `docs/for-agents/plans/043-post-dendritic-audit-cleanups.md`
- `docs/for-agents/plans/044-final-runtime-polish.md`
- `docs/for-agents/plans/045-real-final-cleanups.md`

And matching progress logs under `docs/for-agents/current/`.

After that, active dirs should ideally keep only:
- scaffolds
- truly active execution docs

### B. Tighten the agent-doc set

Living agent docs should be re-audited for overlap:

- `000-operating-rules.md`
  - keep only hard rules
  - remove explanatory material that belongs in architecture or ownership

- `001-repo-map.md`
  - keep it as a map
  - remove architecture explanation that belongs in `002`

- `002-architecture.md`
  - keep runtime model, host composition model, and lower-level module model
  - remove repo-tour or boundary repetition

- `003-module-ownership.md`
  - keep only “who owns what” and boundary rules
  - remove runtime explanation already covered elsewhere

- `005-validation-gates.md`
  - keep current gate taxonomy, required commands, and script categories
  - strip any stale migration framing

- `006-extensibility.md`
  - keep only add-feature/add-host/add-desktop rules and examples
  - avoid re-teaching the whole architecture there

- `007-option-migrations.md`
  - decide whether it still deserves a root slot
  - if it is purely historical now, move it to archive and replace it with a
    shorter note in `999` or `002`

### C. Tighten the human-doc set

Human docs are useful, but some can be simpler:

- `00-start-here.md`
  - should answer only: what this repo is, where to start, what commands matter

- `01-philosophy.md`
  - should stay short and conceptual
  - avoid restating structure

- `02-structure.md`
  - should be the human-facing file tree map
  - avoid deep architecture rules that belong in agent docs

- `03-multi-host.md`
  - should focus on host model and current tracked hosts
  - avoid duplicating onboarding details from workflow docs

- `04-private-overrides.md`
  - should be the single human-facing source for private safety and override
    placement

- `05-dev-environment.md`
  - should focus on actual local dev workflow and tooling

Workflows should be checked for:
- overlap with top docs
- stale terminology
- steps that still mention removed shapes

### D. Normalize terminology repo-wide

Terms that should be normalized in living docs:

- prefer `host owner file` or `host file`
  - avoid vocabulário herdado salvo quando o texto tratar explicitamente de
    contexto histórico

- prefer `persisted paths`
  - avoid nomes herdados para a lista de persistência

- prefer `shared script registry`
  - avoid nomes herdados para catálogo de scripts

- prefer `tracked user owner`
  - avoid confusing “top-level user fact” phrasing that implies import order or
    hierarchy that does not exist in `modules/`

### E. Reduce duplication between root indexes

Current navigation is spread across:
- `README.md`
- `docs/README.md`
- `AGENTS.md`

The target split should be:

- `README.md`
  - brief repo intro + where to go next

- `docs/README.md`
  - authoritative docs navigation

- `AGENTS.md`
  - minimal operator contract for agents in this workspace

If a paragraph appears almost verbatim in two or three of these, one of them is
carrying too much.

### F. Preserve audit value without polluting the present

Historical migration plans/logs still have value:
- debugging old decisions
- proving why certain patterns were rejected
- agent auditability

But they should be clearly secondary:
- archived
- not linked as primary guidance
- not allowed to dominate living terminology

## Execution Plan

### Phase 0: Full Docs Inventory and Classification

For each doc, classify it as:
- keep and tighten
- archive
- merge into another doc
- delete if empty/redundant

Deliverable:
- classification matrix of all living docs and active execution docs

### Phase 1: Shrink the Active Agent Surface

Actions:
- archive completed plans/logs
- keep only scaffolds plus actually active work items in `plans/` and `current/`
- decide whether `007-option-migrations.md` still belongs in root

Validation:
- `./scripts/check-docs-drift.sh`

### Phase 2: Tighten the Core Agent Docs

Actions:
- rewrite for sharper boundaries and less overlap
- keep docs short and role-specific
- normalize terminology

Main targets:
- `000` through `006`
- possibly `007`
- `999`

Validation:
- `./scripts/check-docs-drift.sh`
- spot-read against the runtime (`flake.nix`, `modules/*.nix`, `scripts/*.sh`)

### Phase 3: Tighten the Human Docs

Actions:
- reduce overlap between top docs and workflows
- ensure human docs point to the right workflows rather than re-explaining them
- normalize wording with the runtime

Validation:
- `./scripts/check-docs-drift.sh`

### Phase 4: Clean Root Navigation

Actions:
- slim `README.md`
- slim `docs/README.md`
- keep `AGENTS.md` minimal and operational

Validation:
- `./scripts/check-docs-drift.sh`

### Phase 5: Final Consistency Pass

Actions:
- repo-wide terminology sweep across living docs
- remove stale phrases only if they no longer describe current runtime/tooling

Validation:
- `./scripts/check-docs-drift.sh`
- `rg` sanity sweep across living docs for retired terms

## Decision Rules

Use these to avoid overengineering:

1. If a doc is correct and short, leave it alone.
2. If two docs overlap, prefer deleting text over adding “see also” prose.
3. If history is useful but not operational, archive it instead of polishing it.
4. Never create a new doc when tightening an existing one is enough.
5. Prefer renaming concepts in place over introducing glossary/framework docs.

## Definition of Done

- active docs are materially smaller and easier to navigate
- completed migration material is archived
- living docs use stable terminology
- `README.md`, `docs/README.md`, and `AGENTS.md` stop competing with each other
- docs match the actual runtime and tooling with no stale architectural framing
