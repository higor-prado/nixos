# Portal PATH Override — Interpolação no Helper

## Goal

Mover a interpolação de `portalExecPath` para dentro de `lib/_helpers.nix`, de forma que
os arquivos de composição de desktop importem o resultado já pronto e não precisem mais
fazer a interpolação localmente.

## Scope

In scope:
- `lib/_helpers.nix` — adicionar `portalPathOverrides` interpolado com `rec`
- `modules/desktops/dms-on-niri.nix` — remover `portalExecPath` do let, usar `helpers.portalPathOverrides`
- `modules/desktops/niri-standalone.nix` — idem

Out of scope:
- `modules/features/desktop/niri.nix` — também usa `helpers.portalExecPath` mas num contexto diferente (portal config do gnome); não tocar
- Qualquer outra mudança

## Current State

- `lib/_helpers.nix` — contém só `portalExecPath` (string)
- `dms-on-niri.nix` e `niri-standalone.nix` — importam `_helpers.nix`, extraem `portalExecPath` no `let` local, interpolam manualmente nos dois blocos `xdg.configFile`
- Resultado: interpolação duplicada nos dois arquivos de composição

## Desired End State

- `lib/_helpers.nix` usa `rec` e define `portalPathOverrides` como attrset já interpolado com `portalExecPath`
- `dms-on-niri.nix` e `niri-standalone.nix` atribuem `xdg.configFile = helpers.portalPathOverrides` — sem `portalExecPath` no `let` local
- Interpolação existe num único lugar

## Phases

### Phase 0: Baseline

Validation:
- `nix eval .#nixosConfigurations.predator.config.system.build.toplevel.drvPath`
- `./scripts/run-validation-gates.sh structure`

### Phase 1: Executar

Targets:
- `lib/_helpers.nix`
- `modules/desktops/dms-on-niri.nix`
- `modules/desktops/niri-standalone.nix`

Changes:
- Em `lib/_helpers.nix`: trocar `{` por `rec {`, adicionar `portalPathOverrides` com os dois `xdg.configFile` entries interpolados
- Em `dms-on-niri.nix`: remover `portalExecPath = helpers.portalExecPath` do let, substituir os dois blocos `xdg.configFile` por `xdg.configFile = helpers.portalPathOverrides`
- Em `niri-standalone.nix`: idem

Validation:
- `nix eval .#nixosConfigurations.predator.config.system.build.toplevel.drvPath`
- `./scripts/run-validation-gates.sh structure`

Diff expectation:
- Nenhuma mudança funcional

Commit target:
- `refactor(desktop): move portal PATH interpolation into lib helper`

## Risks

- `niri.nix` também importa `_helpers.nix` para `portalExecPath` — continua funcionando porque `portalExecPath` permanece no helper

## Definition of Done

- `lib/_helpers.nix` tem `portalExecPath` e `portalPathOverrides`
- Nenhum arquivo de composição de desktop faz interpolação de `portalExecPath` localmente
- Gates passam
