# Development Environment

## Tools included via feature modules

| Feature | Tools |
|--------|-------|
| `editor-neovim` | Neovim + 30+ LSP packages |
| `editor-vscode` | VS Code with extensions |
| `editor-emacs` | Emacs (pgtk), Doom setup |
| `editor-zed` | Zed editor |
| `dev-tools` | bat, eza, gh, jq, fd, tree, sd, uv, nixfmt |
| `dev-devenv` | devenv, cachix, devc, direnv+nix-direnv |
| `tui-yazi` | Yazi file manager |
| `tui-lazygit` | Lazygit TUI |
| `tui-lazydocker` | Lazydocker TUI |
| `tui-zellij` | Zellij terminal multiplexer |

## devenv / devc

Create new dev environments from flake templates:

```bash
devc list                    # list available templates
devc python my-project       # new Python project from template
devc python .                # init template in current dir
```

Templates live in `config/devenv-templates/`.

## direnv

`direnv` is configured with `nix-direnv` for fast cached environments.
In project dirs with a `.envrc`, direnv loads automatically.

For devenv projects, `.envrc` contains `use devenv`.

## Neovim config

Nvim config lives in `config/apps/nvim/` and is synced to `~/.config/nvim/`
on every `nixos-rebuild switch` via a home-manager activation script.
