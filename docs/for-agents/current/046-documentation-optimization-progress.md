# Documentation Optimization Progress

## Baseline

- A superfície viva de `docs/for-agents/plans/` e `docs/for-agents/current/`
  ainda está dominada por material de migração já concluído.
- `007-option-migrations.md` continua na raiz dos docs de agentes apesar de ser
  explicitamente aposentado.
- `README.md`, `docs/README.md` e `AGENTS.md` ainda repetem parte demais do
  mapa/documentação operacional.
- A documentação viva ainda alterna entre `host inventory`, `script inventory`
  e outras palavras que já não descrevem o runtime atual com precisão.

## Execution Log

- `007-option-migrations.md` foi tratado como histórico e saiu da superfície
  viva.
- Os planos/progressos concluídos `033`–`045` foram arquivados.
- `README.md`, `docs/README.md` e `AGENTS.md` foram enxugados para papéis mais
  claros.
- A terminologia viva foi apertada para o shape atual do repo.

## Decisions

- `000`–`006` e `999` continuam vivos porque ainda são operacionais e úteis.
- Eu não reescrevi `002-architecture.md` ou os docs humanos maiores sem uma
  necessidade real, porque o problema principal estava na superfície ativa
  grande demais e nos índices/termos, não em arquitetura mal documentada.
- `007-option-migrations.md` foi reduzido a um stub curto de status em vez de
  ser deletado, para manter a numeração estável sem tratá-lo como leitura
  principal.

## Validation

- `./scripts/check-docs-drift.sh`

Passou.

## Result

- `plans/` agora ficou só com o scaffold e o trabalho realmente ativo.
- `current/` agora ficou só com o scaffold e o progresso realmente ativo.
- a documentação viva ficou menor, mais navegável e com menos mistura entre
  estado atual e histórico.
