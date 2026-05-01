# Dev Module Reorganization

## Goal

Reorganize `modules/features/dev/` so every file has a single, narrow, user-facing
responsibility. Eliminate the `dev-tools.nix` grab-bag. Adopt flat naming
consistent with the rest of the repo (`shell/`, `desktop/`, `system/`). Provide
a clear decision tree for where any new development package goes.

## Scope

In scope:

- Extract linters/formatters from `dev-tools.nix` into new `dev/linters.nix`
- Relocate shell enhancers (`bat`, `eza`) and CLI utilities (`jq`, `fd`, `tree`, `sd`) to `shell/core-user-packages.nix`
- Remove duplicate `gh` from `dev-tools.nix` (already provided by `shell/git-gh.nix`)
- Move `uv` from `dev-tools.nix` to `dev/toolchains.nix`
- Delete `dev-tools.nix` after its contents are distributed
- Rename files for consistent flat naming (directory-as-namespace):
  - `dev-devenv.nix` → `devenv.nix`
  - `editor-*.nix` → `editors-*.nix` (4 files)
  - `packages-toolchains.nix` → `toolchains.nix`
  - `packages-docs-tools.nix` → `docs-tools.nix`
  - `llm-agents.nix` → keep (already flat)
- Update published module names to match new filenames
- Update host import lists in `predator.nix`, `aurelius.nix`, `cerebelo.nix`
- Absorb the user's pending unstaged additions (new linters in `dev-tools.nix`, `bun` in `packages-toolchains.nix`) into the new structure

Out of scope:

- Changing any package versions or configuration behavior
- Adding new packages beyond those already staged
- Reorganizing `shell/`, `desktop/`, `system/`, or other categories
- Modifying `config/devenv-templates/`
- Changing `modules/features/shell/monitoring-tools.nix` (naming out of scope)

## Current State

### Files in `modules/features/dev/`

| File                      | Published module(s)                                 | Concern                                                            |
| ------------------------- | --------------------------------------------------- | ------------------------------------------------------------------ |
| `dev-devenv.nix`          | `homeManager.dev-devenv`                            | devenv + cachix + devc + direnv                                    |
| `dev-tools.nix`           | `homeManager.dev-tools`                             | Grab-bag: bat, eza, gh, jq, fd, tree, sd, uv + 12 linters (staged) |
| `editor-emacs.nix`        | `homeManager.editor-emacs`                          | Emacs editor                                                       |
| `editor-neovim.nix`       | `nixos.editor-neovim` + `homeManager.editor-neovim` | Neovim + LSP servers                                               |
| `editor-vscode.nix`       | `homeManager.editor-vscode`                         | VS Code                                                            |
| `editor-zed.nix`          | `homeManager.editor-zed`                            | Zed editor                                                         |
| `llm-agents.nix`          | `homeManager.llm-agents`                            | LLM coding agents                                                  |
| `packages-docs-tools.nix` | `homeManager.packages-docs-tools`                   | Documentation tools                                                |
| `packages-toolchains.nix` | `homeManager.packages-toolchains`                   | Build toolchains + runtimes (+ bun staged)                         |

### Host import status (hmDev lists)

| Host     | Current imports                                                                                                                     |
| -------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| predator | dev-devenv, dev-tools, editor-emacs, editor-neovim, editor-vscode, editor-zed, llm-agents, packages-docs-tools, packages-toolchains |
| aurelius | dev-devenv, dev-tools, editor-neovim, packages-toolchains                                                                           |
| cerebelo | dev-tools, editor-neovim                                                                                                            |

### Pending unstaged changes

- `dev-tools.nix`: +12 linters (yamllint, sqlfluff, hadolint, mypy, rubocop, shellcheck, golangci-lint, ktlint, tflint, terraform-ls, zls) — these will land in the new `linters.nix`
- `packages-toolchains.nix`: +bun — will land in renamed `toolchains.nix`

### Naming inconsistency with rest of repo

Other categories use flat naming (directory is the namespace):

- `shell/fish.nix` → `homeManager.fish`
- `desktop/hyprland.nix` → `homeManager.hyprland`
- `system/ssh.nix` → `homeManager.ssh`

Dev currently uses redundant prefixes (`dev-devenv`, `packages-toolchains`) or
arbitrary subcategory prefixes (`editor-emacs`, `packages-docs-tools`).

## Desired End State

### Files in `modules/features/dev/`

| File                 | Published module(s)                                   | Concern                              |
| -------------------- | ----------------------------------------------------- | ------------------------------------ |
| `devenv.nix`         | `homeManager.devenv`                                  | Dev environments                     |
| `editors-emacs.nix`  | `homeManager.editors-emacs`                           | Emacs editor                         |
| `editors-neovim.nix` | `nixos.editors-neovim` + `homeManager.editors-neovim` | Neovim + LSP                         |
| `editors-vscode.nix` | `homeManager.editors-vscode`                          | VS Code                              |
| `editors-zed.nix`    | `homeManager.editors-zed`                             | Zed editor                           |
| `llm-agents.nix`     | `homeManager.llm-agents`                              | LLM agents                           |
| `toolchains.nix`     | `homeManager.toolchains`                              | Toolchains + runtimes + pkg managers |
| `linters.nix`        | `homeManager.linters`                                 | Linters + formatters                 |
| `docs-tools.nix`     | `homeManager.docs-tools`                              | Documentation tools                  |

### Content distribution

| Package(s)                                    | From            | To                                        |
| --------------------------------------------- | --------------- | ----------------------------------------- |
| `bat`, `eza` + `programs.bat`, `programs.eza` | `dev-tools.nix` | `shell/core-user-packages.nix`            |
| `gh`                                          | `dev-tools.nix` | Removed (duplicate of `shell/git-gh.nix`) |
| `jq`, `fd`, `tree`, `sd`                      | `dev-tools.nix` | `shell/core-user-packages.nix`            |
| `uv`                                          | `dev-tools.nix` | `toolchains.nix`                          |
| 12 linters (nixfmt, yamllint, etc.)           | `dev-tools.nix` | `linters.nix` (new)                       |
| `dev-tools.nix`                               | —               | Deleted                                   |

### Host imports after change

| Host     | New hmDev imports                                                                                               |
| -------- | --------------------------------------------------------------------------------------------------------------- |
| predator | devenv, editors-emacs, editors-neovim, editors-vscode, editors-zed, llm-agents, toolchains, linters, docs-tools |
| aurelius | devenv, editors-neovim, toolchains, linters                                                                     |
| cerebelo | editors-neovim, linters                                                                                         |

Note: cerebelo currently gets `uv` via `dev-tools.nix`. After the split, `uv`
lives in `toolchains.nix` which cerebelo does not import (headless ARM SBC server
has no use for Python package manager). This is an intentional cleanup — the old
`dev-tools` grab-bag was never a deliberate dependency.

## Phases

### Phase 0: Baseline

Capture starting state. Run validation gates. Confirm all hosts eval.

Validation:

- `./scripts/run-validation-gates.sh structure`
- `nix eval path:$PWD#nixosConfigurations.predator.config.system.stateVersion`
- `git status` — note uncommitted changes
- `git stash` pending changes to work on clean HEAD, then re-apply into new structure

### Phase 1: Create `linters.nix` from staged linter additions

Targets:

- NEW: `modules/features/dev/linters.nix`

Changes:

- Create `linters.nix` publishing `homeManager.linters` with all 12+ linters
  currently staged in `dev-tools.nix` diff plus `nixfmt` which is already committed
- The new file follows the flat naming pattern from the start

Validation:

- `nix eval path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path` — confirms module exists and is auto-imported
- No host imports linters yet — this is just a creation

Diff expectation:

- New file `modules/features/dev/linters.nix` with ~30 lines

Commit target:

- `feat(dev): add linters module for language linters and formatters`

### Phase 2: Relocate `bat`, `eza`, `jq`, `fd`, `tree`, `sd` to `shell/core-user-packages.nix`

Targets:

- `modules/features/shell/core-user-packages.nix`
- `modules/features/dev/dev-tools.nix`

Changes:

- Add `programs.bat.enable = true`, `programs.eza.enable = true` to `core-user-packages.nix`
- Add `jq`, `fd`, `tree`, `sd` to `home.packages` in `core-user-packages.nix`
- Remove the same from `dev-tools.nix`
- Remove duplicate `gh` from `dev-tools.nix`

Validation:

- `nix eval` on predator — confirms packages are reachable through `core-user-packages`
- `git diff modules/features/shell/core-user-packages.nix` — review additions
- `git diff modules/features/dev/dev-tools.nix` — review removals

Diff expectation:

- `core-user-packages.nix`: +bat, eza, jq, fd, tree, sd (~10 lines added)
- `dev-tools.nix`: -bat, eza, gh, jq, fd, tree, sd (~8 lines removed)

Commit target:

- `refactor(dev): relocate shell tools from dev-tools to core-user-packages`

### Phase 3: Move `uv` to `toolchains.nix` and absorb staged `bun`

Targets:

- `modules/features/dev/packages-toolchains.nix`
- `modules/features/dev/dev-tools.nix`

Changes:

- Add `uv` to `packages-toolchains.nix` (moved from dev-tools.nix)
- Absorb staged `bun` addition into the same commit
- Remove `uv` from `dev-tools.nix`
- At this point, `dev-tools.nix` only contains the 12 linters

Validation:

- `nix eval` on predator and aurelius (both import packages-toolchains)
- Confirm `uv` + `bun` are present

Diff expectation:

- `packages-toolchains.nix`: +uv, +bun
- `dev-tools.nix`: -uv

Commit target:

- `refactor(dev): move uv to toolchains, add bun`

### Phase 4: Rename files for consistent flat naming

Targets (all renames — git mv):

- `dev-devenv.nix` → `devenv.nix`
- `editor-emacs.nix` → `editors-emacs.nix`
- `editor-neovim.nix` → `editors-neovim.nix`
- `editor-vscode.nix` → `editors-vscode.nix`
- `editor-zed.nix` → `editors-zed.nix`
- `packages-toolchains.nix` → `toolchains.nix`
- `packages-docs-tools.nix` → `docs-tools.nix`

Internal changes in each renamed file:

- Update `flake.modules.*` published name to match new filename

Validation (after each rename batch):

- `git status` — confirms renames are tracked
- `cat <file>` — confirms published module name matches filename
- `nix eval` on predator — auto-import picks up renamed files via git index

Diff expectation:

- 7 renames, each with a 1-line internal change (the published module name)

Commit target:

- `refactor(dev): adopt flat naming convention for dev modules`

### Phase 5: Delete `dev-tools.nix` — remaining linters now live in `linters.nix`

Targets:

- DELETE: `modules/features/dev/dev-tools.nix`
- The linters that were in `dev-tools.nix` are already in `linters.nix` from Phase 1

Changes:

- `git rm modules/features/dev/dev-tools.nix`

Validation:

- `./scripts/check-docs-drift.sh` or `./scripts/run-validation-gates.sh structure` — confirms no stale references to `dev-tools`
- `grep -r "dev-tools" modules/` — must return nothing (hosts will be updated in next phase)

Commit target:

- `refactor(dev): remove dev-tools grab-bag, superseded by linters module`

### Phase 6: Update host import lists

Targets:

- `modules/hosts/predator.nix`
- `modules/hosts/aurelius.nix`
- `modules/hosts/cerebelo.nix`

Changes (predator hmDev):

```diff
-  homeManager.dev-devenv
-  homeManager.dev-tools
-  homeManager.editor-emacs
-  homeManager.editor-neovim
-  homeManager.editor-vscode
-  homeManager.editor-zed
-  homeManager.packages-docs-tools
-  homeManager.packages-toolchains
+  homeManager.devenv
+  homeManager.editors-emacs
+  homeManager.editors-neovim
+  homeManager.editors-vscode
+  homeManager.editors-zed
+  homeManager.toolchains
+  homeManager.linters
+  homeManager.docs-tools
```

Changes (aurelius hmDev):

```diff
-  homeManager.dev-devenv
-  homeManager.dev-tools
-  homeManager.editor-neovim
-  homeManager.packages-toolchains
+  homeManager.devenv
+  homeManager.editors-neovim
+  homeManager.linters
+  homeManager.toolchains
```

Changes (cerebelo hmDev):

```diff
-  homeManager.dev-tools
-  homeManager.editor-neovim
+  homeManager.editors-neovim
+  homeManager.linters
```

Also update `nixos.editor-neovim` → `nixos.editors-neovim` in all three host NixOS import lists.

Validation:

- `nix eval path:$PWD#nixosConfigurations.predator.config.system.build.toplevel.drvPath`
- `nix eval path:$PWD#nixosConfigurations.aurelius.config.system.build.toplevel.drvPath`
- `nix eval path:$PWD#nixosConfigurations.cerebelo.config.system.build.toplevel.drvPath`
- `./scripts/run-validation-gates.sh structure`

Diff expectation:

- 3 host files updated with renamed module references

Commit target:

- `refactor(hosts): update hmDev imports for dev module reorg`

### Phase 7: Final validation gates

Validation:

- `./scripts/run-validation-gates.sh structure`
- `./scripts/check-repo-public-safety.sh`
- `grep -r "dev-tools\|editor-emacs\|editor-vscode\|editor-zed\|packages-toolchains\|packages-docs-tools\|dev-devenv" modules/` — must return nothing
- `grep -r "editor-neovim" modules/` — only allowed in `docs/` historical references, not in active module code
- `ls modules/features/dev/` — exactly 9 files matching desired end state
- Full build for predator: `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`
- HM build for predator: `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`

Diff expectation:

- Only the files listed in this plan should change

## Risks

- **Auto-import visibility**: `import-tree` only sees files tracked by git. All
  `git mv` operations must happen before eval. New files must be `git add`-ed
  before eval. (Lesson 22)
- **Stale references**: `editor-neovim` appears in `docs/` archives — those are
  historical and intentionally excluded from docs-drift checks. Only active
  module code must be updated.
- **Cerebelo loses `uv`**: Previously inherited via `dev-tools` grab-bag. If
  cerebelo genuinely needs `uv`, add `homeManager.toolchains` to its hmDev list.
  This is a conscious cleanup, not a regression.
- **host import ordering**: The hmDev list is concatenated in host files. Order
  does not affect evaluation — modules are merged by `lib.mkMerge`.

## Definition of Done

- [ ] `modules/features/dev/dev-tools.nix` deleted
- [ ] `modules/features/dev/linters.nix` created with all linters
- [ ] `modules/features/shell/core-user-packages.nix` has bat, eza, jq, fd, tree, sd
- [ ] No duplicate `gh` in dev modules
- [ ] All 7 renames completed with matching published module names
- [ ] All 3 host files updated with new module references
- [ ] `nix eval` on all 3 hosts passes
- [ ] `nix build --no-link` on predator passes (NixOS + HM)
- [ ] `./scripts/run-validation-gates.sh structure` passes
- [ ] `./scripts/check-repo-public-safety.sh` passes
- [ ] No stale references to old module names in active module code
- [ ] User's pending staged additions (linters, bun) absorbed into new structure
