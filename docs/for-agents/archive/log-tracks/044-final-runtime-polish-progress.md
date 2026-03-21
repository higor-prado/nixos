# Final Runtime Polish Progress

## Baseline

- `modules/users/higorprado.nix` ainda usa `lib.types.str` para `username`.
- `scripts/check-desktop-composition-matrix.sh` ainda hardcodeia
  `"higorprado"` no harness.
- `scripts/check-extension-contracts.sh` ainda tem variáveis com concatenação
  artificial para legado.
- `scripts/check-feature-legacy-role-conditionals.sh` ainda usa `grep`.
- `040` e `041` ainda estão em `docs/for-agents/plans/`.

## Execution

- `username` foi apertado para `lib.types.singleLineStr`.
- `check-desktop-composition-matrix.sh` agora deriva o `username` do runtime
  real do repo antes de montar o harness.
- `check-extension-contracts.sh` perdeu concatenação artificial de strings
  legadas.
- `check-feature-legacy-role-conditionals.sh` trocou `grep` por `rg`.

## Adjustment

- A primeira tentativa de derivar `username` via
  `nix eval path:$PWD#nixosConfigurations.predator.config.username` estava no
  shape errado para esse flake.
- A correção final foi usar `nix_eval_sole_hm_user_for_host predator`, que
  deriva o usuário real do runtime canônico em vez de hardcodear ou tentar ler
  uma attr que o output não expõe.

## Archive

- `040-final-structural-cleanups.md` foi movido para `archive/plans/`.
- `041-hardware-boundary-cleanup.md` foi movido para `archive/plans/`.

## Validation

- `./scripts/check-desktop-composition-matrix.sh`
- `./scripts/check-extension-contracts.sh`
- `./scripts/check-feature-legacy-role-conditionals.sh`
- `./scripts/check-docs-drift.sh`
- `./scripts/run-validation-gates.sh structure`
- `./scripts/run-validation-gates.sh all`

Tudo passou. Só apareceram os warnings já conhecidos de `xorg.libxcb` e
`system.stateVersion` na desktop matrix.
