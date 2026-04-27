#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=lib/common.sh
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
# shellcheck source=lib/nix_eval.sh
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib/nix_eval.sh"
enter_repo_root "${BASH_SOURCE[0]}"
repo_root="$(pwd)"
username="$(
  nix_eval_sole_hm_user_for_host predator
)"

report_fail() {
  log_fail "desktop-matrix" "$1"
}

require_cmds "desktop-matrix" "jq" "nix"

json="$(
  nix_eval_json_expr "
    let
      flake = builtins.getFlake \"path:${repo_root}\";
      inherit (flake.modules) nixos;
      system = \"x86_64-linux\";
      username = \"${username}\";
      inputs = flake.inputs;
      lib = flake.inputs.nixpkgs.lib;
      composition = nixos.\"desktop-hyprland-standalone\";
      systemConfig = lib.nixosSystem {
        inherit system;
        modules = [
          inputs.hyprland.nixosModules.default
          inputs.home-manager.nixosModules.home-manager
          inputs.keyrs.nixosModules.default
          nixos.hyprland
          nixos.regreet
          composition
          {
            nixpkgs.hostPlatform.system = system;
            networking.hostName = \"desktop-matrix\";
            system.stateVersion = \"26.05\";
            users.users.\${username} = { isNormalUser = true; };
            home-manager.users.\${username}.home.stateVersion = \"25.11\";
            nixpkgs.config.allowUnfree = true;
            boot.isContainer = true;
            networking.useHostResolvConf = lib.mkForce false;
            fileSystems.\"/\" = {
              device = \"none\";
              fsType = \"tmpfs\";
            };
          }
        ];
      };
      cfg = systemConfig.config;
    in
    {
      greeter = if cfg.programs.regreet.enable then true else false;
      systemDrv = cfg.system.build.toplevel.drvPath;
    }
  "
)"

if [[ "$(jq -r '.greeter' <<<"$json")" != "true" ]]; then
  report_fail "hyprland-standalone feature 'greeter' expected 'true'"
  exit 1
fi

system_drv="$(jq -r '.systemDrv' <<<"$json")"
if [[ "$system_drv" != /nix/store/* ]]; then
  report_fail "invalid system drv path for hyprland-standalone: ${system_drv}"
  exit 1
fi

echo "[desktop-matrix] ok: hyprland-standalone (systemDrv/features)"
echo "[desktop-matrix] hyprland-only desktop experience evaluated successfully"
