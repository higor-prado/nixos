# Post-Dendritic Audit Cleanups

## Goal

Remover os últimos cheiros estruturais que sobraram depois da migração, sem
inventar abstração nova nem fazer refactor cosmético.

## Scope

In scope:
- `scripts/check-option-declaration-boundary.sh`
- `modules/features/desktop/niri.nix`
- `modules/features/desktop/dms.nix`
- `scripts/check-desktop-composition-matrix.sh`
- `scripts/check-extension-contracts.sh`
- opcionalmente `modules/users/higorprado.nix`, se houver ganho real

Out of scope:
- `flake.lock`
- mudanças de comportamento das features
- novos contracts/options/helpers

## Confirmed Problems

1. `scripts/check-option-declaration-boundary.sh` ainda permite
   `modules/users/higorprado.nix` por nome literal, não por ownership.
2. `modules/features/desktop/niri.nix` e `modules/features/desktop/dms.nix`
   ainda capturam `topConfig = config` só para ler `username`.
3. `scripts/check-desktop-composition-matrix.sh` ainda hardcodeia o usuário
   real do repo (`higorprado`) no harness.
4. `scripts/check-extension-contracts.sh` ainda carrega checks históricos para
   paths mortos (`modules/options/*`, `modules/profiles/*`).
5. `modules/users/higorprado.nix` pode talvez ser enxugado, mas isso só entra
   se remover estrutura real, não se for mera preferência estética.

## Desired End State

- boundary script fala em categoria/ownership, não em um filename concreto
- `niri.nix` e `dms.nix` capturam só o fato estreito que usam
- desktop matrix usa fixture identity, não o usuário real do repo
- extension contracts deixa de carregar lixo histórico morto
- `higorprado.nix` só muda se houver simplificação real

## Phases

### Phase 0: Baseline

Validation:
- `sed -n '1,220p' scripts/check-option-declaration-boundary.sh`
- `sed -n '1,140p' modules/features/desktop/niri.nix`
- `sed -n '1,140p' modules/features/desktop/dms.nix`
- `sed -n '80,130p' scripts/check-desktop-composition-matrix.sh`
- `sed -n '50,110p' scripts/check-extension-contracts.sh`
- `sed -n '1,120p' modules/users/higorprado.nix`

### Phase 1: Boundary + Narrow Captures

Changes:
- `check-option-declaration-boundary.sh`: trocar o allowlist literal do arquivo
  do usuário por uma regra de ownership estreita (`modules/users/`)
- `niri.nix` e `dms.nix`: matar `topConfig = config` e capturar só
  `userName = config.username`

Validation:
- `./scripts/run-validation-gates.sh structure`
- `nix eval --raw path:$PWD#nixosConfigurations.predator.config.system.stateVersion`
- `nix eval --raw path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.stateVersion`

### Phase 2: Test Harness Cleanup

Changes:
- `check-desktop-composition-matrix.sh`: usar um usuário fixture explícito, não
  o nome real do repo
- `check-extension-contracts.sh`: remover checks de paths mortos que já não
  fazem parte do runtime vivo

Validation:
- `./scripts/run-validation-gates.sh structure`
- `bash tests/scripts/run-validation-gates-fixture-test.sh`
- `./scripts/check-desktop-composition-matrix.sh`

### Phase 3: Decide Whether `higorprado.nix` Deserves Trimming

Decision rule:
- só mexer se der para remover aliases/linhas sem piorar legibilidade ou
  reintroduzir duplicação
- se o ganho for só estético, não mexer

Validation:
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`
- `./scripts/run-validation-gates.sh all`

## Definition of Done

- nenhuma regra estrutural depende do nome literal `higorprado.nix`
- `niri`/`dms` não capturam mais `config` inteiro para ler `username`
- desktop matrix não conhece o usuário real do repo
- extension contracts não carrega mais resíduo histórico morto
- `higorprado.nix` só muda se houver simplificação material
