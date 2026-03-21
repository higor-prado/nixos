# Docs Index and Wording Cleanup

## Goal

Fechar os últimos problemas reais depois da otimização da documentação:

- limpar o estado inconsistente do índice git deixado pelo arquivamento
- ajustar o pouco vocabulário vivo que ainda ficou atrás do shape atual

Sem overengineering:
- não mexer no runtime
- não reescrever docs corretas só por estilo
- não criar docs novas além do tracking normal do trabalho

## Confirmed Problems

1. O índice git ainda carrega deleções staged para os arquivos antigos de
   `docs/for-agents/plans/` e `docs/for-agents/current/`, mesmo depois do
   commit que já adicionou as versões arquivadas.

2. [docs/for-humans/02-structure.md](/home/higorprado/nixos/docs/for-humans/02-structure.md)
   ainda descreve `modules/hosts/` de forma mais fraca do que o resto da doc
   viva.

3. [docs/for-agents/002-architecture.md](/home/higorprado/nixos/docs/for-agents/002-architecture.md)
   ainda usa alguns restos de vocabulário histórico que podem ser substituídos
   por linguagem mais direta.

## Desired End State

- o worktree não fica com deleções staged acidentais por causa do arquivamento
- a documentação viva usa terminologia estável e atual
- nenhuma mudança de runtime entra nessa slice

## Phases

### Phase 0: Baseline

Validation:
- `git status --short`
- `git diff --name-status --cached`
- `sed -n '1,220p' docs/for-agents/002-architecture.md`
- `sed -n '1,220p' docs/for-humans/02-structure.md`

### Phase 1: Fix the Git Index State

Actions:
- remover do índice as deleções staged que sobraram do arquivamento anterior
- garantir que o estado final reflita só:
  - arquivos arquivados já commitados
  - docs vivas realmente editadas agora
  - `flake.lock` do usuário intocado

Validation:
- `git status --short`
- `git diff --name-status --cached`

### Phase 2: Tighten the Last Live Wording

Actions:
- ajustar `docs/for-humans/02-structure.md`
- ajustar `docs/for-agents/002-architecture.md`
- fazer só mudanças de terminologia/clareza com ganho real

Validation:
- `./scripts/check-docs-drift.sh`
- `rg -n '<retired wording patterns>' docs/for-agents docs/for-humans README.md AGENTS.md --glob '!docs/for-agents/archive/**'`

### Phase 3: Final Sanity Pass

Actions:
- conferir que não entrou nenhuma mudança fora de docs
- conferir que o índice está limpo de resíduo do arquivamento

Validation:
- `git status --short`
- `./scripts/check-docs-drift.sh`

## Definition of Done

- o índice git deixa de carregar deleções staged acidentais
- a terminologia viva fica coerente com o shape atual do repo
- nenhuma mudança de runtime ou infra entra por acidente
