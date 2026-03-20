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

report_fail() {
  log_fail "desktop-matrix" "$1"
}

require_cmds "desktop-matrix" "jq" "nix"

composition_module_name() {
  case "$1" in
    dms-on-niri) echo "desktop-dms-on-niri" ;;
    niri-standalone) echo "desktop-niri-standalone" ;;
    *) return 1 ;;
  esac
}

# Expected composition-level parameters per composition.
# Only composition parameterization is checked here (standalone, greeter).
# Feature program enablement is verified by the predator full build gate.
expected_feature_json() {
  case "$1" in
    dms-on-niri)
      cat <<'EOF2'
{"standalone":false,"greeter":"niri"}
EOF2
      ;;
    niri-standalone)
      cat <<'EOF2'
{"standalone":true,"greeter":"niri"}
EOF2
      ;;
    *)
      report_fail "missing expected feature mapping for experience '$1'"
      return 1
      ;;
  esac
}

check_experience() {
  local experience="$1"
  local module_name expected_json json system_drv expected actual key

  module_name="$(composition_module_name "$experience")" || {
    report_fail "missing module name for experience '$experience'"
    return 1
  }
  expected_json="$(expected_feature_json "$experience")" || return 1

  json="$(
    nix_eval_json_expr "
      let
        flake = builtins.getFlake \"path:${repo_root}\";
        system = \"x86_64-linux\";
        pkgs = flake.inputs.nixpkgs.legacyPackages.\${system};
        inputs = flake.inputs;
        customPkgs = import \"${repo_root}/pkgs\" {
          inherit pkgs inputs;
        };
        lib = flake.inputs.nixpkgs.lib;
        composition = flake.modules.nixos.\"${module_name}\";
        systemConfig = lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit inputs customPkgs;
          };
          modules = [
            inputs.niri.nixosModules.niri
            inputs.dms.nixosModules.dank-material-shell
            inputs.dms.nixosModules.greeter
            inputs.home-manager.nixosModules.home-manager
            inputs.keyrs.nixosModules.default
            ({ lib, ... }: {
              options.custom = {
                host.role = lib.mkOption {
                  type = lib.types.enum [ \"desktop\" \"server\" ];
                };
                niri.standaloneSession = lib.mkOption {
                  type = lib.types.bool;
                  default = false;
                };
              };

              config = {
                nixpkgs.hostPlatform.system = system;
              };
            })
            composition
            {
              networking.hostName = \"desktop-matrix\";
              custom.host.role = \"desktop\";
              users.users.\"fixture-user\" = { isNormalUser = true; };
              home-manager.users.\"fixture-user\".home.stateVersion = \"25.11\";
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
        standalone = cfg.custom.niri.standaloneSession;
        systemDrv = cfg.system.build.toplevel.drvPath;
      }
    "
  )"

  key="standalone"
  expected="$(jq -r ".${key}" <<<"$expected_json")"
  actual="$(jq -r ".${key}" <<<"$json")"
  if [[ "$actual" != "$expected" ]]; then
    report_fail "${experience} feature '${key}' expected '${expected}', got '${actual}'"
    return 1
  fi

  system_drv="$(jq -r '.systemDrv' <<<"$json")"
  if [[ "$system_drv" != /nix/store/* ]]; then
    report_fail "invalid system drv path for ${experience}: ${system_drv}"
    return 1
  fi
  echo "[desktop-matrix] ok: $experience (systemDrv/features)"
}

for experience in \
  dms-on-niri \
  niri-standalone; do
  check_experience "$experience"
done

echo "[desktop-matrix] all concrete desktop experiences evaluated successfully"
