# Development Environment

## Tools included via feature modules

| Feature | Tools |
|--------|-------|
| `editor-neovim` | Neovim + 30+ LSP packages |
| `editor-vscode` | VS Code with extensions |
| `editor-emacs` | Emacs (pgtk), Doom setup |
| `editor-zed` | Zed editor |
| `llm-agents` | Claude Code, Codex, Crush, Kilocode, Opencode |
| `dev-tools` | bat, eza, gh, jq, fd, tree, sd, uv, nixfmt |
| `dev-devenv` | devenv, cachix, devc, direnv+nix-direnv |
| `monitoring-tools` | htop, btop, bottom, fastfetch |
| `tui-tools` | Lazygit, Lazydocker, Yazi, Zellij |

## devenv / devc

Create new dev environments from flake templates:

```bash
devc list                    # list available templates
devc python my-project       # new Python project from template
devc python .                # init template in current dir
```

By default, `devc` uses the repo's tracked embedded template set. To point it at
another flake that exposes `templates`, override `DEVC_FLAKE`.

The tracked template sources live in `config/devenv-templates/`.

## direnv

`direnv` is configured with `nix-direnv` for fast cached environments.
In project dirs with a `.envrc`, direnv loads automatically.

For devenv projects, `.envrc` contains `use devenv`.

## Neovim config

Nvim config lives in `config/apps/nvim/` and is synced to `~/.config/nvim/`
on every `nixos-rebuild switch` via a home-manager activation script.

## Pre-commit hooks

The repo tracks `.pre-commit-config.yaml` with a public safety hook that blocks
commits containing private data (usernames, SSH keys, emails, IPs).

One-time setup after cloning:

```bash
nix run nixpkgs#pre-commit -- install
```

This is intentionally imperative — declarative alternatives (global `core.hooksPath`,
activation scripts with hardcoded paths) all have worse tradeoffs for a per-repo hook.

CI runs the same check on push as a fallback. Bypass locally with
`git commit --no-verify` if needed.