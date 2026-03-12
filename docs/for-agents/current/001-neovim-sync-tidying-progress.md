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
- not committed

## Final State

- first cleanup slice completed and validated
- swap files remain enabled by user preference; the tracked config does not override `swapfile`
- remaining audit work:
  - deeper plugin override cleanup in [config/apps/nvim/lua/plugins](/home/higorprado/nixos/config/apps/nvim/lua/plugins), especially the remaining DAP defensive code
  - review of whether [config/apps/nvim/lazyvim.json](/home/higorprado/nixos/config/apps/nvim/lazyvim.json) still includes extras whose value no longer justifies the inherited complexity
