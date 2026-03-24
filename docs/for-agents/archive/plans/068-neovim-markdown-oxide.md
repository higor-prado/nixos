# Neovim: Add Markdown-Oxide LSP

## Goal

Substituir `marksman` por `markdown-oxide` como servidor LSP para arquivos Markdown
no neovim. O markdown-oxide oferece integração com Zettelkasten/wiki-links e navegação
entre notas além do que o marksman cobre.

## Scope

In scope:
- Trocar `marksman` por `markdown-oxide` em `home.packages` no módulo editor-neovim
- Configurar o servidor `markdown_oxide` em `lsp.lua`
- Suprimir o servidor `marksman` que o LazyVim extra `lang.markdown` injeta

Out of scope:
- Instalar plugins de Zettelkasten ou wiki (obsidian.nvim, etc.)
- Alterar qualquer outro servidor LSP
- Alterar a lista de extras do LazyVim (`lazyvim.json`)
- Configurar `marksman` como fallback ou dual-server

## Current State

- `marksman` está em `home.packages` em `modules/features/dev/editor-neovim.nix:89`
- LazyVim extra `lazyvim.plugins.extras.lang.markdown` está ativo (`lazyvim.json:10`)
  — esse extra injeta `marksman` como servidor LSP via lspconfig
- `lsp.lua` já tem um fallback handler que ignora servidores sem executável no PATH;
  se `marksman` for removido dos pacotes, ele não iniciará — mas o servidor ainda fica
  declarado na config do lspconfig, gerando mensagem de aviso
- `markdown-oxide` está disponível no nixpkgs como `pkgs.markdown-oxide` (versão 0.25.10)
- O nome lspconfig do markdown-oxide é `markdown_oxide` (underscore)

## Desired End State

- `markdown-oxide` instalado via `home.packages`
- `marksman` removido de `home.packages`
- `lsp.lua` configura `markdown_oxide` com `filetypes = { "markdown", "md" }` e desabilita
  `marksman` explicitamente (evita warning do lspconfig)
- `nix eval` sem erros; rebuild funcional

## Phases

### Phase 0: Baseline

Validation:
- `nix eval .#nixosConfigurations.predator.config.home-manager.users.higorprado.home.packages --apply 'ps: map (p: p.name) ps' 2>&1 | grep marksman`
  — deve retornar exatamente uma entrada contendo `marksman`

### Phase 1: Trocar pacote

Arquivo: `modules/features/dev/editor-neovim.nix`

Changes:
- Remover `marksman` da lista `home.packages`
- Adicionar `markdown-oxide` na mesma posição (após `gopls` / bloco go)

Diff expectation:
```diff
-          marksman
+          markdown-oxide
```

Validation:
- `nix eval .#nixosConfigurations.predator.config.home-manager.users.higorprado.home.packages --apply 'ps: map (p: p.name) ps' 2>&1 | grep -E 'marksman|markdown-oxide'`
  — deve aparecer apenas `markdown-oxide-*`, sem `marksman`

Commit target:
- `feat(neovim): replace marksman with markdown-oxide in home.packages`

### Phase 2: Configurar LSP

Arquivo: `config/apps/nvim/lua/plugins/lsp.lua`

Changes:
- Dentro do bloco `opts.servers`, desabilitar `marksman` explicitamente:
  ```lua
  opts.servers["marksman"] = { enabled = false }
  ```
- Adicionar entrada para `markdown_oxide`:
  ```lua
  opts.servers["markdown_oxide"] = {
      cmd = { "markdown-oxide" },
      filetypes = { "markdown" },
  }
  ```

Validation:
- `nix eval .#nixosConfigurations.predator.config.home-manager.users.higorprado.home.activation 2>&1 | head -5`
  — sem erros de eval
- Após rebuild e abertura de arquivo `.md` no neovim:
  `:LspInfo` deve mostrar `markdown_oxide` conectado, sem `marksman`

Commit target:
- `feat(neovim): configure markdown_oxide lsp, disable marksman`

## Risks

- LazyVim injeta `marksman` via `lang.markdown` extra. O fallback handler em `lsp.lua`
  já pula servidores sem executável, mas não suprime o aviso. Desabilitar explicitamente
  com `enabled = false` é mais limpo.
- `markdown_oxide` (underscore) é o nome lspconfig — diferente do nome do pacote nixpkgs
  `markdown-oxide` (hífen). Não confundir.

## Definition of Done

- `home.packages` contém `markdown-oxide`, não `marksman`
- `lsp.lua` configura `markdown_oxide` e marca `marksman` como `enabled = false`
- `nix eval` do host predator sem erros
- `:LspInfo` em arquivo `.md` exibe `markdown_oxide` ativo
