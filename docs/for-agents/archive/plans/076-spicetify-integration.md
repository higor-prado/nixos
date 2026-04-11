# Spicetify Integration Plan

## Goal

Adicionar Spicetify de forma declarativa e coerente com a arquitetura atual do
repo, mantendo Spotify/Spicetify no owner certo, evitando instalação duplicada
de Spotify e reutilizando o tema Catppuccin já centralizado no desktop.

## Scope

In scope:
- adicionar `spicetify-nix` como input do flake
- integrar o módulo do Spicetify no runtime do `predator`
- decidir o owner correto para Spotify/Spicetify no Home Manager
- habilitar os plugins `adblockify`, `hidePodcasts`, e `shuffle`
- alinhar o tema do Spicetify ao Catppuccin já usado no sistema

Out of scope:
- trocar o cliente de música já existente (`mpd`, `rmpc`, `spotatui`)
- introduzir um segundo owner paralelo só para tema
- customizações profundas de CSS/JS do Spicetify além do setup inicial
- instalar `pkgs.spotify` manualmente fora do módulo do Spicetify

## Current State

- Não há nenhuma referência a `spicetify` ou `spotify` no repo hoje.
- O owner atual de cliente de música é
  [music-client.nix](/home/higorprado/nixos/modules/features/desktop/music-client.nix),
  um módulo Home Manager que já concentra apps e serviços de música do usuário.
- O tema visual compartilhado do desktop já fica centralizado em
  [theme-base.nix](/home/higorprado/nixos/modules/features/desktop/theme-base.nix),
  onde o flavor Catppuccin atual é `mocha` com accent `lavender`.
- O `flake.nix` ainda não tem o input `spicetify-nix`.
- A documentação do `spicetify-nix` fornecida pelo usuário já indica duas
  restrições importantes:
  - a integração deve ser declarativa via módulo
  - o módulo instala o Spotify automaticamente, então `pkgs.spotify` não deve
    ser adicionado em paralelo

## Desired End State

- O repo passa a ter um único caminho declarativo para Spotify + Spicetify.
- O owner continua coerente:
  - tema compartilhado segue centralizado em `theme-base.nix`
  - comportamento do cliente de música fica em `music-client.nix` ou em um
    owner adjacente claramente justificado
- O Spicetify usa Catppuccin com o mesmo flavor já adotado no desktop.
- Os três plugins desejados ficam habilitados declarativamente.
- O `predator` constrói sem instalar Spotify por fora do módulo.

## Phases

### Phase 0: Baseline

Validation:
- `rg -n "spicetify|spotify" modules docs flake.nix flake.lock`
- `nix flake metadata`
- `./scripts/run-validation-gates.sh structure`

### Phase 1: Add Flake Input

Targets:
- [flake.nix](/home/higorprado/nixos/flake.nix)
- `flake.lock`

Changes:
- adicionar `inputs.spicetify-nix.url = "github:Gerg-L/spicetify-nix";`
- manter `inputs.nixpkgs.follows = "nixpkgs"` se o input suportar esse padrão

Validation:
- `nix flake metadata`
- `./scripts/run-validation-gates.sh structure`

Diff expectation:
- apenas o grafo do flake muda; ainda sem efeito no runtime do `predator`

Commit target:
- `feat(flake): add spicetify-nix input`

### Phase 2: Wire the Owner Cleanly

Targets:
- [music-client.nix](/home/higorprado/nixos/modules/features/desktop/music-client.nix)
- possivelmente um helper `_` adjacente se o tema precisar de dados compartilhados
- [predator.nix](/home/higorprado/nixos/modules/hosts/predator.nix) apenas se a
  composição precisar de um import novo

Changes:
- preferir integrar Spicetify no owner já existente de música, porque ele já
  é o owner HM de apps/serviços musicais do usuário
- importar `inputs.spicetify-nix.homeManagerModules.spicetify` no lugar certo
- habilitar:
  - `adblockify`
  - `hidePodcasts`
  - `shuffle`
- não adicionar `pkgs.spotify`

Validation:
- `./scripts/run-validation-gates.sh structure`
- `nix eval path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.packages`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`

Diff expectation:
- o HM closure do `predator` passa a incluir o Spotify/Spicetify declarativo
- não aparece instalação paralela de `pkgs.spotify`

Commit target:
- `feat(music): add declarative spicetify setup`

### Phase 3: Reuse Centralized Theme Facts

Targets:
- [theme-base.nix](/home/higorprado/nixos/modules/features/desktop/theme-base.nix)
- [music-client.nix](/home/higorprado/nixos/modules/features/desktop/music-client.nix)

Changes:
- evitar duplicar `mocha` em mais um lugar se der para reutilizar o fato já
  centralizado do tema
- escolher a solução mais estreita e dendrítica:
  - ou referenciar o fato já exposto pelo tema atual
  - ou extrair um pequeno helper adjacente só para os fatos de flavor/accent
- aplicar Catppuccin no Spicetify com o mesmo flavor do restante do desktop

Validation:
- `./scripts/run-validation-gates.sh structure`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`

Diff expectation:
- tema do Spicetify alinhado ao tema do desktop sem criar um segundo centro de verdade

Commit target:
- `refactor(theme): reuse catppuccin facts for spicetify`

### Phase 4: Final Runtime Proof

Targets:
- runtime do `predator`

Changes:
- nenhuma mudança estrutural grande; apenas ajustes finos se a ativação real pedir

Validation:
- `nh os test path:$HOME/nixos --out-link "$HOME/nixos/result"`
- abrir Spotify e confirmar:
  - Spicetify ativo
  - tema Catppuccin correto
  - `adblockify`, `hidePodcasts`, e `shuffle` funcionando

Diff expectation:
- nenhum diff estrutural adicional além de eventuais ajustes pequenos

Commit target:
- `docs(music): record supported spicetify workflow`

## Risks

- O módulo do `spicetify-nix` instala Spotify por conta própria; instalar
  Spotify em paralelo quebraria a coerência do owner.
- Duplicar `mocha` em `music-client.nix` resolveria rápido, mas enfraqueceria a
  centralização de tema já existente.
- Forçar um owner novo só para Spicetify provavelmente seria sobre-engenharia,
  já que `music-client.nix` já possui a semântica mais próxima.

## Definition of Done

- `spicetify-nix` está no `flake.nix`
- Spotify + Spicetify são configurados declarativamente no owner correto
- os plugins desejados estão habilitados
- o tema do Spicetify segue o Catppuccin já adotado no sistema
- não existe instalação paralela de `pkgs.spotify`
- o `predator` constrói e o runtime real confirma o resultado
