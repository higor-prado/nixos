# Neovim Sync Tidying Progress

## Status

In progress

## Related Plan

- [001-neovim-sync-tidying.md](/home/higorprado/nixos/docs/for-agents/plans/001-neovim-sync-tidying.md)

## Baseline

- [modules/features/dev/editor-neovim.nix](/home/higorprado/nixos/modules/features/dev/editor-neovim.nix) enables Neovim and syncs [config/apps/nvim](/home/higorprado/nixos/config/apps/nvim) to `$HOME/.config/nvim` with `rsync -a --delete`.
- Confirmed template remnants at baseline:
  - [config/apps/nvim/lua/config/autocmds.lua](/home/higorprado/nixos/config/apps/nvim/lua/config/autocmds.lua)
  - [config/apps/nvim/lua/config/keymaps.lua](/home/higorprado/nixos/config/apps/nvim/lua/config/keymaps.lua)
  - [config/apps/nvim/README.md](/home/higorprado/nixos/config/apps/nvim/README.md)
  - [config/apps/nvim/LICENSE](/home/higorprado/nixos/config/apps/nvim/LICENSE)
- LazyVim runtime proof:
  - upstream [LazyVim init.lua](/home/higorprado/.local/share/nvim/lazy/LazyVim/lua/lazyvim/config/init.lua) only loads `config.autocmds` and `config.keymaps` if those files exist, so deleting empty local stubs is safe
  - the markdown diagnostics came from the LazyVim markdown extra mapping `markdown` to `markdownlint-cli2`
- The Nix feature also owns `home.packages` entries plus the `nvim-runtime-cleanup` service/timer, both of which need audit before changes.
- The worktree was already dirty before this task in at least:
  - [config/apps/nvim/lua/plugins/core.lua](/home/higorprado/nixos/config/apps/nvim/lua/plugins/core.lua)
  - [flake.lock](/home/higorprado/nixos/flake.lock)

## Slices

### Slice 1

- created the active plan and progress documents after correcting the workflow miss
- captured baseline Neovim ownership and sync behavior
- validated that LazyVim treats missing local `config.autocmds` and `config.keymaps` files as optional
- validated that markdown diagnostics were coming from the LazyVim markdown extra via `nvim-lint`

Validation:
- `git status --short`
- `nix flake metadata path:$PWD`
- targeted local inspection of [LazyVim init.lua](/home/higorprado/.local/share/nvim/lazy/LazyVim/lua/lazyvim/config/init.lua)

Diff result:
- documentation only

Commit:
- none

### Slice 2

- removed confirmed template carryover from the synced tree:
  - [config/apps/nvim/lua/config/autocmds.lua](/home/higorprado/nixos/config/apps/nvim/lua/config/autocmds.lua)
  - [config/apps/nvim/lua/config/keymaps.lua](/home/higorprado/nixos/config/apps/nvim/lua/config/keymaps.lua)
  - [config/apps/nvim/README.md](/home/higorprado/nixos/config/apps/nvim/README.md)
  - [config/apps/nvim/LICENSE](/home/higorprado/nixos/config/apps/nvim/LICENSE)
- changed [config/apps/nvim/lua/plugins/lint.lua](/home/higorprado/nixos/config/apps/nvim/lua/plugins/lint.lua) to disable markdown and MDX lint mappings explicitly instead of relying on the `markdownlint-cli2` binary being present
- removed `nodePackages."markdownlint-cli2"` from [editor-neovim.nix](/home/higorprado/nixos/modules/features/dev/editor-neovim.nix) because that package was only supporting the now-disabled markdown lint path

Validation:
- `nix flake metadata path:$PWD`
- `nix eval --raw path:$PWD#nixosConfigurations.predator.config.system.stateVersion`
- `nix eval --raw path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.stateVersion`
- `nix build --no-link --print-out-paths path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`
- temporary-config headless Neovim startup: `startup-ok`
- temporary-config headless Neovim plugin probe: merged `nvim-lint` config now reports `markdown = {}`
- `./scripts/check-repo-public-safety.sh`

Diff result:
- tracked Neovim sync tree no longer includes starter-template README/license or empty config stubs
- markdown diagnostics are explicitly disabled for markdown buffers in the repo-managed config

Commit:
- included in `refactor(neovim): tidy synced config`

### Slice 3

- removed the inert disabled `vim-startuptime` stub from [config/apps/nvim/lua/plugins/performance.lua](/home/higorprado/nixos/config/apps/nvim/lua/plugins/performance.lua)
- kept the `LazyProfile` command wiring intact because it is still live config on top of optional `noice.nvim`

Validation:
- temporary-config headless Neovim startup: `startup-ok`
- `nix build --no-link --print-out-paths path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`

Diff result:
- one disabled plugin stub removed from the synced Neovim tree

Commit:
- included in `refactor(neovim): tidy synced config`

### Slice 4

- disabled the remaining Mason path in the tracked Neovim config:
  - [config/apps/nvim/lua/plugins/lsp.lua](/home/higorprado/nixos/config/apps/nvim/lua/plugins/lsp.lua) now disables `mason.nvim`, `mason-lspconfig.nvim`, and `mason-tool-installer.nvim`
  - [config/apps/nvim/lua/plugins/dap.lua](/home/higorprado/nixos/config/apps/nvim/lua/plugins/dap.lua) now disables `mason-nvim-dap.nvim`
- this removed the contradiction where LazyVim extras were still feeding Mason `ensure_installed` lists despite the tracked config intending Nix-managed tools only

Validation:
- temporary-config headless Neovim startup: `startup-ok`
- temporary-config plugin probe: `mason.nvim`, `mason-lspconfig.nvim`, `mason-tool-installer.nvim`, and `mason-nvim-dap.nvim` all resolve to `nil` in the merged plugin graph
- `nix build --no-link --print-out-paths path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`

Diff result:
- Mason is no longer part of the live repo-managed Neovim setup

Commit:
- included in `refactor(neovim): tidy synced config`

### Slice 5

- pruned Nix-side Neovim packages in [editor-neovim.nix](/home/higorprado/nixos/modules/features/dev/editor-neovim.nix) that no longer matched any active merged server/formatter/linter path:
  - removed `nixpkgs-fmt`
  - removed `statix`
  - removed `nodePackages.yaml-language-server`
  - removed `shellcheck`
- kept packages that still map to active merged config, such as `marksman`, `shfmt`, `gopls`, `gofumpt`, `vtsls`, `vscode-js-debug`, and `nodePackages.vscode-langservers-extracted`

Validation:
- temporary-config merged LSP server probe still shows the expected active server set
- temporary-config merged `nvim-lint` probe still shows only `fish`, `go`, and empty markdown entries
- `nix build --no-link --print-out-paths path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`
- `./scripts/check-repo-public-safety.sh`

Diff result:
- Nix-side editor package list is closer to the actual live Neovim configuration

Commit:
- included in `refactor(neovim): tidy synced config`

### Slice 6

- simplified [config/apps/nvim/lua/plugins/lsp.lua](/home/higorprado/nixos/config/apps/nvim/lua/plugins/lsp.lua) by removing the now-redundant loop that injected `mason = false` into every server config
- removed the redundant `mason = false` field from the explicit `nil` server entry
- kept the parts that still materially affect runtime behavior:
  - binary-aware `opts.setup["*"]`
  - Python interpreter selection
  - `ts_ls` disable
  - `vtsls` enable and filetypes
  - explicit `nil` server wiring

Validation:
- temporary-config merged LSP probe still shows:
  - `nil` server with explicit `cmd` and `filetypes`
  - `ts_ls.enabled = false`
  - `vtsls.enabled = true`
  - expected `opts.setup` keys remain active
- `nix build --no-link --print-out-paths path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`

Diff result:
- one Mason-era mutation layer removed from the tracked LSP config without changing the merged active server shape

Commit:
- included in `refactor(neovim): simplify lsp and dap overrides`

### Slice 7

- simplified [config/apps/nvim/lua/plugins/dap.lua](/home/higorprado/nixos/config/apps/nvim/lua/plugins/dap.lua) without changing the resulting active DAP configurations:
  - replaced the JS/TS reset-and-reinsert loop with a direct singleton assignment for each filetype
  - narrowed the Lua fallback so it only provisions the `luau` config when the `lua-local` adapter actually exists
- kept the runtime behavior unchanged for the active temp-config DAP tables

Validation:
- temporary-config headless Neovim probe after `lazy.load({ plugins = { "nvim-dap" } })` still shows the same active configurations for:
  - `lua`
  - `luau`
  - `javascript`
  - `typescript`
- `nix build --no-link --print-out-paths path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`

Diff result:
- DAP config is simpler while preserving the merged active adapter/configuration shape

Commit:
- included in `refactor(neovim): simplify lsp and dap overrides`

### Slice 8

- removed the startup-time notification from [config/apps/nvim/init.lua](/home/higorprado/nixos/config/apps/nvim/init.lua)
- classified it as leftover bring-up/performance instrumentation rather than core editor behavior

Validation:
- temporary-config headless Neovim startup: `startup-ok`
- `nix build --no-link --print-out-paths path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`

Diff result:
- Neovim no longer emits a startup timing notification on every `VimEnter`

Commit:
- `a30ee87 refactor(neovim): remove startup instrumentation`

### Slice 9

- reconciled [config/apps/nvim/lazy-lock.json](/home/higorprado/nixos/config/apps/nvim/lazy-lock.json) with the resolved plugin graph from a temporary synced config
- removed confirmed stale lock entries for disabled Mason plugins:
  - `mason.nvim`
  - `mason-lspconfig.nvim`
  - `mason-nvim-dap.nvim`
- added lock entries for active plugins that were previously missing from the tracked lockfile:
  - `local-lua-debugger-vscode`
  - `markdown-preview.nvim`
  - `neotest-golang`
  - `nvim-dap-go`
  - `render-markdown.nvim`
- intentionally kept `rustaceanvim` in the lockfile because it is conditionally enabled by the Rust toolchain being available in PATH, so the temporary baseline environment alone is not enough proof that it is stale

Validation:
- temporary-config headless Neovim resolved plugin graph still starts cleanly: `startup-ok`
- temporary-config diff between resolved plugin keys and tracked lockfile keys becomes empty after the lockfile update
- `nix build --no-link --print-out-paths path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`

Diff result:
- tracked Lazy lock metadata now matches the live repo-managed plugin graph, excluding intentionally conditional Rust support

Commit:
- included in `refactor(neovim): reconcile lazy lockfile`

### Slice 10

- removed the undocumented inline `commit` pin from [config/apps/nvim/lua/plugins/treesitter.lua](/home/higorprado/nixos/config/apps/nvim/lua/plugins/treesitter.lua)
- kept the actual runtime Treesitter behavior overrides intact:
  - extra parsers for `bash`, `regex`, and `rust`
  - `jsonc` filtered out from `ensure_installed`
  - `auto_install = false`
  - `jsonc` kept in `ignore_install`
- this restores a single source of truth for plugin versions by letting [lazy-lock.json](/home/higorprado/nixos/config/apps/nvim/lazy-lock.json) own the Treesitter revision instead of an extra inline pin

Validation:
- temporary-config headless Neovim probe shows the resolved `nvim-treesitter` spec no longer carries an inline `commit`
- temporary-config headless Neovim probe still reports the expected Treesitter overrides:
  - `ensure_installed = { "bash", "regex", "rust" }`
  - `auto_install = false`
  - `ignore_install = { "jsonc" }`
- `./scripts/run-validation-gates.sh`
- `./scripts/check-repo-public-safety.sh`

Diff result:
- the tracked config no longer duplicates Treesitter version selection outside [lazy-lock.json](/home/higorprado/nixos/config/apps/nvim/lazy-lock.json)
- runtime Treesitter parser/install behavior is unchanged

Commit:
- included in `refactor(neovim): drop treesitter spec pin`

### Slice 11

- removed the stale `luasnip` completion source from [config/apps/nvim/lua/plugins/autocomplete.lua](/home/higorprado/nixos/config/apps/nvim/lua/plugins/autocomplete.lua)
- kept the rest of the completion customization intact:
  - Copilot completion source
  - LSP, buffer, and path sources
  - `<Tab>` / `<S-Tab>` snippet navigation through Neovim's native `vim.snippet` API
- this was classified as dead config because the resolved plugin graph does not include `LuaSnip` or `cmp_luasnip`, so a `luasnip` cmp source entry had no corresponding provider in the live setup

Validation:
- temporary-config resolved plugin graph confirms `LuaSnip = false` and `cmp_luasnip = false`
- temporary-config merged `nvim-cmp` source list is now:
  - `copilot`
  - `nvim_lsp`
  - `buffer`
  - `path`
- `./scripts/run-validation-gates.sh`
- `./scripts/check-repo-public-safety.sh`

Diff result:
- the tracked completion config no longer advertises a snippet source with no live provider plugin
- completion source ordering and native snippet keymaps remain intact

Commit:
- included in `refactor(neovim): remove stale cmp source`

### Slice 12

- removed the redundant local TypeScript server override block from [config/apps/nvim/lua/plugins/lsp.lua](/home/higorprado/nixos/config/apps/nvim/lua/plugins/lsp.lua)
- kept the local LSP customizations that still materially differ from upstream:
  - binary-aware `opts.setup["*"]`
  - project Python interpreter injection for `pyright` / `basedpyright`
  - explicit `nil` server wiring
- this was classified as dead/redundant config because the imported LazyVim TypeScript extra already disables `ts_ls` and configures `vtsls`, and its filetype list is more complete than the local override

Validation:
- temporary-config runtime probe inside a fake TypeScript project shows:
  - `vtsls` still resolves through the imported LazyVim TypeScript extra
  - `vtsls.filetypes` now includes the fuller upstream list:
    - `javascript`
    - `javascriptreact`
    - `javascript.jsx`
    - `typescript`
    - `typescriptreact`
    - `typescript.tsx`
  - local `nil` server wiring remains available
- `./scripts/run-validation-gates.sh`
- `./scripts/check-repo-public-safety.sh`

Diff result:
- the tracked LSP config no longer restates TypeScript defaults already provided by the imported extra
- the resulting TypeScript filetype coverage is more complete than before

Commit:
- included in `refactor(neovim): drop redundant ts lsp override`

### Slice 13

- removed the local [rcarriga/nvim-dap-ui](/home/higorprado/nixos/config/apps/nvim/lua/plugins/dap.lua) override block from [config/apps/nvim/lua/plugins/dap.lua](/home/higorprado/nixos/config/apps/nvim/lua/plugins/dap.lua)
- kept the local DAP customizations that still materially differ from upstream:
  - Mason disable
  - `local-lua-debugger-vscode`
  - Nix-managed adapter command selection
  - Python, Lua, and JS/TS adapter/configuration wiring
- this was classified as redundant config because the imported LazyVim `dap.core` extra already configures the DAP UI open/close listeners upstream

Validation:
- temporary-config runtime probe after loading `nvim-dap` and `nvim-dap-ui` shows:
  - upstream `dapui_config` listeners still exist for `event_initialized`, `event_terminated`, and `event_exited`
  - local Lua, Python, and JavaScript adapter/configuration wiring still resolves
- `./scripts/run-validation-gates.sh`
- `./scripts/check-repo-public-safety.sh`

Diff result:
- the tracked DAP config no longer duplicates DAP UI listener registration already provided by the imported extra
- local Nix-managed adapter wiring remains intact

Commit:
- included in `refactor(neovim): drop redundant dap ui hook`

## Final State

- first cleanup slice completed and validated
- swap files remain enabled by user preference; the tracked config does not override `swapfile`
- remaining audit work:
  - review of remaining Neovim bring-up customizations for actual current value versus inherited LazyVim behavior
  - review of whether [config/apps/nvim/lazyvim.json](/home/higorprado/nixos/config/apps/nvim/lazyvim.json) still includes extras whose value no longer justifies the inherited complexity
