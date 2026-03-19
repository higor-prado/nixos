{ ... }:
{
  den.aspects.dev-devenv = {
    provides.to-users.homeManager =
      { lib, pkgs, ... }:
      let
        devc = pkgs.writeShellApplication {
          name = "devc";
          runtimeInputs = with pkgs; [
            coreutils
            jq
            nix
          ];
          text = ''
            usage() {
              cat <<'EOF'
            Usage:
              devc list
              devc <template> [target]
              devc help

            Examples:
              devc python new_project
              devc python .

            Environment:
              DEVC_FLAKE  Flake reference that exposes templates (default: path:$HOME/nixos)
            EOF
            }

            if [[ $# -eq 0 ]]; then
              usage >&2
              exit 1
            fi

            case "$1" in
              help|-h|--help)
                usage
                exit 0
                ;;
            esac

            flake_ref="''${DEVC_FLAKE:-path:$HOME/nixos}"

            if [[ "$1" == "list" ]]; then
              nix flake show "$flake_ref" --json \
                | jq -r '.templates // {} | keys[]' \
                | sort
              exit 0
            fi

            if [[ $# -gt 2 ]]; then
              echo "Error: too many arguments." >&2
              usage >&2
              exit 1
            fi

            template="$1"
            target="''${2:-.}"
            template_ref="$flake_ref#$template"

            if [[ "$target" == "." ]]; then
              exec nix flake init -t "$template_ref"
            fi

            exec nix flake new "$target" -t "$template_ref"
          '';
        };
      in
      {
        home.packages = with pkgs; [
          devenv
          cachix
          devc
        ];

        programs.direnv = {
          enable = true;
          nix-direnv.enable = true;
          config.global.hide_env_diff = true;
        };

        xdg.configFile."direnv/direnvrc".text = lib.mkForce (
          builtins.readFile (
            pkgs.runCommand "devenv-direnvrc" { buildInputs = [ pkgs.devenv ]; } ''
              devenv direnvrc > $out
            ''
          )
        );
      };
  };
}
