# Real Final Cleanups Progress

## Baseline

- `check-desktop-composition-matrix.sh` declarava expectativa para `greeter`,
  mas só validava `standalone`.
- `dms-on-niri.nix` e `niri-standalone.nix` ainda repetem o mesmo bloco HM de
  override de portal.
- `modules/users/higorprado.nix` ainda carregava aliases locais redundantes.
- `hardware/predator/_persistence-inventory.nix` tinha conteúdo legítimo, mas
  nome ruim.

## Decision

- A duplicação entre `dms-on-niri.nix` e `niri-standalone.nix` foi mantida por
  enquanto.
- Extrair esse bloco agora exigiria um helper/shared file que esconderia mais
  do que ajudaria.
- Como são dois arquivos curtos e explícitos, isso ainda é melhor do que
  introduzir infraestrutura nova só para DRY.

## Execution

- `check-desktop-composition-matrix.sh` agora valida `standalone` e `greeter`.
- O expected de `niri-standalone` foi corrigido para `greeter = null`, porque
  essa composição não importa `dms`.
- `modules/users/higorprado.nix` foi enxugado removendo aliases redundantes.
- `_persistence-inventory.nix` foi renomeado para `persisted-paths.nix`.
- `hardware/predator/impermanence.nix`,
  `scripts/report-persistence-candidates.sh` e o fixture test correspondente
  foram alinhados ao nome novo.

## Validation

- `./scripts/check-desktop-composition-matrix.sh`
- `bash tests/scripts/report-persistence-candidates-test.sh`
- `./scripts/check-docs-drift.sh`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`
- `./scripts/run-validation-gates.sh all`

Tudo passou. Só ficaram os warnings já conhecidos de `system.stateVersion` na
desktop matrix e `xorg.libxcb`.
